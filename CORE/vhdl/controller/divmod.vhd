library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity divmod is
   generic (
      G_SIZE : natural
   );
   port (
      clk_i           : in    std_logic;
      rst_i           : in    std_logic;
      s_ready_o       : out   std_logic;
      s_valid_i       : in    std_logic;
      s_numerator_i   : in    std_logic_vector(G_SIZE - 1 downto 0);
      s_denominator_i : in    std_logic_vector(G_SIZE - 1 downto 0);
      m_ready_i       : in    std_logic;
      m_valid_o       : out   std_logic;
      m_quotient_o    : out   std_logic_vector(G_SIZE - 1 downto 0);
      m_remainder_o   : out   std_logic_vector(G_SIZE - 1 downto 0)
   );
end entity divmod;

architecture synthesis of divmod is

   type   state_type is (IDLE_ST, BUSY_ST);
   signal state : state_type := IDLE_ST;

   signal s_denominator : std_logic_vector(G_SIZE - 1 downto 0);

begin

   s_ready_o <= m_ready_i when state = IDLE_ST else
                '0';

   divmod_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if m_ready_i = '1' then
            m_valid_o <= '0';
         end if;

         case state is

            when IDLE_ST =>
               if s_valid_i = '1' and s_ready_o = '1' then
                  s_denominator <= s_denominator_i;
                  if s_numerator_i < s_denominator_i then
                     m_quotient_o  <= (others => '0');
                     m_remainder_o <= s_numerator_i;
                     m_valid_o     <= '1';
                  else
                     m_remainder_o <= s_numerator_i - s_denominator_i;
                     m_quotient_o  <= to_stdlogicvector(1, G_SIZE);
                     state         <= BUSY_ST;
                  end if;
               end if;

            when BUSY_ST =>
               if m_remainder_o < s_denominator then
                  m_valid_o <= '1';
                  state     <= IDLE_ST;
               else
                  m_remainder_o <= m_remainder_o - s_denominator;
                  m_quotient_o  <= m_quotient_o + 1;
               end if;

         end case;

         if rst_i = '1' then
            state     <= IDLE_ST;
            m_valid_o <= '0';
         end if;
      end if;
   end process divmod_proc;

end architecture synthesis;

