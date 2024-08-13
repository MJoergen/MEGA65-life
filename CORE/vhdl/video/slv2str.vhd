library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- Convert an integer to a decimal string.
-- The output string is right justified and padded with spaces.

entity slv2str is
   port (
      clk_i  : in    std_logic;
      rst_i  : in    std_logic;
      data_i : in    std_logic_vector(15 downto 0);
      str_o  : out   std_logic_vector(79 downto 0)
   );
end entity slv2str;

architecture synthesis of slv2str is

   signal dec_valid : std_logic;
   signal dec_ready : std_logic;
   signal dec_data  : std_logic_vector(3 downto 0);
   signal dec_last  : std_logic;

begin

   slv_to_dec_inst : entity work.slv_to_dec
      generic map (
         G_DATA_SIZE => 16
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_valid_i => '1',
         s_ready_o => open,
         s_data_i  => data_i,
         m_valid_o => dec_valid,
         m_ready_i => dec_ready,
         m_data_o  => dec_data,
         m_last_o  => dec_last
      ); -- slv_to_dec_count_inst

   dec_ready <= '1';

   str_proc : process (clk_i)
      variable tmp_v : std_logic_vector(79 downto 0);
   begin
      if rising_edge(clk_i) then
         if dec_valid then
            -- Most significant digit is presented first,
            -- which is then shifted right.
            tmp_v := "0011" & dec_data & tmp_v(79 downto 8);
            if dec_last then
               str_o <= tmp_v;
               tmp_v := X"20202020202020202020";
            end if;
         end if;
      end if;
   end process str_proc;

end architecture synthesis;

