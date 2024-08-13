library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_statistics is
end entity tb_statistics;

architecture simulation of tb_statistics is

   constant C_STAT_SIZE : natural := 4;
   constant C_ROWS      : integer := 4;
   constant C_COLS      : integer := 48;

   -- Clock, reset, and enable
   signal   running : std_logic   := '1';
   signal   rst     : std_logic   := '1';
   signal   clk     : std_logic   := '1';

   signal   dut_addr    : std_logic_vector(9 downto 0);
   signal   dut_wr_data : std_logic_vector(C_COLS - 1 downto 0);
   signal   dut_wr_en   : std_logic;
   signal   dut_total   : std_logic_vector(16 * C_STAT_SIZE - 1 downto 0);

begin

   rst <= '1', '0' after 100 ns;
   clk <= running and not clk after 5 ns;

   dut_inst : entity work.statistics
      generic map (
         G_CELL_BITS => 1,
         G_STAT_SIZE => C_STAT_SIZE,
         G_ROWS      => C_ROWS,
         G_COLS      => C_COLS
      )
      port map (
         clk_i     => clk,
         rst_i     => rst,
         addr_i    => dut_addr,
         wr_data_i => dut_wr_data,
         wr_en_i   => dut_wr_en,
         m_ready_i => '1',
         m_valid_o => open,
         m_data_o  => dut_total
      ); -- dut_inst

   test_proc : process
      --

      procedure write_row (
         addr : integer range 0 to C_ROWS - 1;
         data : std_logic_vector(C_COLS - 1 downto 0)
      ) is
      begin
         dut_addr    <= to_stdlogicvector(addr, 10);
         dut_wr_data <= data;
         dut_wr_en   <= '1';
         wait until clk = '1';
         dut_wr_en   <= '0';
      end procedure write_row;

   --
   begin
      dut_wr_en <= '0';
      wait until rst = '0';
      wait until clk = '1';
      report "Test started";

      -- 48 digits of pi.
      write_row(0, X"314159265358");
      write_row(1, X"979323846264");
      write_row(2, X"338327950288");
      write_row(3, X"419716939937");
      wait until clk = '1';
      wait until clk = '1';
      wait until clk = '1';
      wait until clk = '1';
      wait until clk = '1';
      assert dut_total = X"0022_0018_001E_0050"
         report "Got: " & to_hstring(dut_total);

      running   <= '0';
      report "Test finished";
   end process test_proc;

end architecture simulation;

