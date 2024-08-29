library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- Convert an integer to a decimal string.
-- The output string is right justified and padded with spaces.

entity bin2bcd is
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;
      s_ready_o : out   std_logic;
      s_valid_i : in    std_logic;
      s_data_i  : in    std_logic_vector(15 downto 0);
      m_ready_i : in    std_logic;
      m_valid_o : out   std_logic;
      m_data_o  : out   std_logic_vector(79 downto 0)
   );
end entity bin2bcd;

architecture synthesis of bin2bcd is

   type     state_type is (IDLE_ST, BUSY_ST);
   signal   state : state_type       := IDLE_ST;
   signal   index : natural range 0 to 4;
   signal   pad   : std_logic_vector(7 downto 0);

   signal   divmod_s_ready     : std_logic;
   signal   divmod_s_valid     : std_logic;
   signal   divmod_s_numerator : std_logic_vector(15 downto 0);
   signal   divmod_m_ready     : std_logic;
   signal   divmod_m_valid     : std_logic;
   signal   divmod_m_quotient  : std_logic_vector(15 downto 0);
   signal   divmod_m_remainder : std_logic_vector(15 downto 0);

   type     pow_ten_type is array(0 to 4) of natural;
   constant C_POW_TEN : pow_ten_type := (1, 10, 100, 1000, 10000);

begin

   s_ready_o      <= m_ready_i and divmod_s_ready when state = IDLE_ST else
                     '0';

   fsm_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if m_ready_i = '1' then
            m_valid_o <= '0';
         end if;

         if divmod_s_ready = '1' then
            divmod_s_valid <= '0';
         end if;

         case state is

            when IDLE_ST =>
               if s_valid_i = '1' and s_ready_o = '1' then
                  divmod_s_numerator <= s_data_i;
                  divmod_s_valid     <= '1';
                  index              <= 4;
                  state              <= BUSY_ST;
                  pad                <= X"20";
                  m_data_o           <= X"20202020202020202020";
               end if;

            when BUSY_ST =>
               if divmod_m_valid = '1' then
                  m_data_o(index * 8 + 7 downto index * 8) <= pad;
                  if divmod_m_quotient /= 0 or index = 0 then
                     m_data_o(index * 8 + 7 downto index * 8) <= X"3" & divmod_m_quotient(3 downto 0);
                     pad                                      <= X"30";
                  end if;

                  if index > 0 then
                     divmod_s_numerator <= divmod_m_remainder;
                     divmod_s_valid     <= '1';
                     index              <= index - 1;
                  else
                     m_valid_o <= '1';
                     state     <= IDLE_ST;
                  end if;
               end if;

         end case;

         if rst_i = '1' then
            m_valid_o      <= '0';
            divmod_s_valid <= '0';
            state          <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

   divmod_m_ready <= m_ready_i;

   divmod_inst : entity work.divmod
      generic map (
         G_SIZE => 16
      )
      port map (
         clk_i           => clk_i,
         rst_i           => rst_i,
         s_ready_o       => divmod_s_ready,
         s_valid_i       => divmod_s_valid,
         s_numerator_i   => divmod_s_numerator,
         s_denominator_i => to_stdlogicvector(C_POW_TEN(index), 16),
         m_ready_i       => divmod_m_ready,
         m_valid_o       => divmod_m_valid,
         m_quotient_o    => divmod_m_quotient,
         m_remainder_o   => divmod_m_remainder
      ); -- divmod_inst

end architecture synthesis;

