----------------------------------------------------------------------------------
-- MiSTer2MEGA65 Framework
--
-- MEGA65 main file that contains the whole machine
--
-- MiSTer2MEGA65 done by sy2002 and MJoergen in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity controller_wrapper is
   generic (
      G_MAIN_CLK_HZ   : natural;
      G_UART_BAUDRATE : natural;
      G_CELL_BITS     : natural;
      G_STAT_SIZE     : natural;
      G_ROWS          : integer;
      G_COLS          : integer
   );
   port (
      main_clk_i                : in    std_logic;
      main_rst_i                : in    std_logic;
      main_kb_key_num_i         : in    integer range 0 to 79;
      main_kb_key_pressed_n_i   : in    std_logic;
      uart_tx_o                 : out   std_logic;
      uart_rx_i                 : in    std_logic;
      main_init_density_i       : in    natural range 0 to 100;
      main_init_border_i        : in    natural range 0 to 50;
      main_generational_speed_i : in    natural range 0 to 31;
      main_auto_stop_en_i       : in    std_logic;
      main_life_ready_i         : in    std_logic;
      main_life_step_o          : out   std_logic;
      main_bottom_o             : out   std_logic_vector(80 * (G_STAT_SIZE + 1) - 1 downto 0);

      main_life_start_row_o     : out   natural range 0 to G_ROWS - 1;
      main_life_start_col_o     : out   natural range 0 to G_COLS - 1;
      main_life_addr_i          : in    std_logic_vector(9 downto 0);
      main_life_rd_data_o       : out   std_logic_vector(G_CELL_BITS * G_COLS - 1 downto 0);
      main_life_wr_data_i       : in    std_logic_vector(G_CELL_BITS * G_COLS - 1 downto 0);
      main_life_wr_en_i         : in    std_logic;
      main_board_addr_o         : out   std_logic_vector(9 downto 0);
      main_board_rd_data_i      : in    std_logic_vector(G_CELL_BITS * G_COLS - 1 downto 0);
      main_board_wr_data_o      : out   std_logic_vector(G_CELL_BITS * G_COLS - 1 downto 0);
      main_board_wr_en_o        : out   std_logic;

      qnice_clk_i               : in    std_logic;
      qnice_rst_i               : in    std_logic;
      qnice_addr_i              : in    std_logic_vector(27 downto 0);
      qnice_data_i              : in    std_logic_vector(15 downto 0);
      qnice_data_o              : out   std_logic_vector(15 downto 0);
      qnice_ce_i                : in    std_logic;
      qnice_we_i                : in    std_logic
   );
end entity controller_wrapper;

architecture synthesis of controller_wrapper is

   signal main_key_valid : std_logic;
   signal main_key_data  : std_logic_vector(7 downto 0);

   signal main_uart_rx_ready : std_logic;
   signal main_uart_rx_valid : std_logic;
   signal main_uart_rx_data  : std_logic_vector(7 downto 0);
   signal main_uart_tx_ready : std_logic;
   signal main_uart_tx_valid : std_logic;
   signal main_uart_tx_data  : std_logic_vector(7 downto 0);

   signal main_cmd_ready : std_logic;
   signal main_cmd_valid : std_logic;
   signal main_cmd_data  : std_logic_vector(7 downto 0);

   signal main_controller_busy    : std_logic;
   signal main_controller_addr    : std_logic_vector(9 downto 0);
   signal main_controller_wr_data : std_logic_vector(G_CELL_BITS * G_COLS - 1 downto 0);
   signal main_controller_wr_en   : std_logic;

   signal main_life_gens : std_logic_vector(15 downto 0);

   signal main_stat_ready : std_logic_vector(G_STAT_SIZE downto 0);
   signal main_stat_valid : std_logic;
   signal main_stat_data  : std_logic_vector(16 * G_STAT_SIZE - 1 downto 0);

   signal main_bottom       : std_logic_vector(80 * (G_STAT_SIZE + 1) - 1 downto 0);
   signal main_bottom_d     : std_logic_vector(80 * (G_STAT_SIZE + 1) - 1 downto 0);
   signal main_bottom_dd    : std_logic_vector(80 * (G_STAT_SIZE + 1) - 1 downto 0);
   signal main_bottom_ready : std_logic;
   signal main_bottom_valid : std_logic_vector(G_STAT_SIZE downto 0);
   signal main_auto_stop    : std_logic;

   signal main_drives_load : std_logic;
   signal main_drives_save : std_logic;
   signal main_drives_ack  : std_logic;
   signal main_drives_busy : std_logic;

   signal main_drives_addr    : std_logic_vector(9 downto 0);
   signal main_drives_rd_data : std_logic_vector(G_CELL_BITS * G_COLS - 1 downto 0);
   signal main_drives_wr_data : std_logic_vector(G_CELL_BITS * G_COLS - 1 downto 0);
   signal main_drives_wr_en   : std_logic;

begin

   main_board_addr_o    <= main_drives_addr when main_drives_busy = '1' else
                           main_controller_addr when main_controller_busy = '1' else
                           main_life_addr_i;
   main_board_wr_data_o <= main_drives_wr_data when main_drives_busy = '1' else
                           main_controller_wr_data when main_controller_busy = '1' else
                           main_life_wr_data_i;
   main_board_wr_en_o   <= main_drives_wr_en when main_drives_busy = '1' else
                           main_controller_wr_en when main_controller_busy = '1' else
                           main_life_wr_en_i;
   main_life_rd_data_o  <= main_board_rd_data_i;

   keyboard_inst : entity work.keyboard
      generic map (
         G_MAIN_CLK_HZ => G_MAIN_CLK_HZ
      )
      port map (
         main_clk_i              => main_clk_i,
         main_rst_i              => main_rst_i,
         main_kb_key_num_i       => main_kb_key_num_i,
         main_kb_key_pressed_n_i => main_kb_key_pressed_n_i,
         main_key_valid_o        => main_key_valid,
         main_key_data_o         => main_key_data
      ); -- keyboard_inst

   uart_inst : entity work.uart
      generic map (
         G_DIVISOR => G_MAIN_CLK_HZ / G_UART_BAUDRATE
      )
      port map (
         clk_i      => main_clk_i,
         rst_i      => main_rst_i,
         uart_rx_i  => uart_rx_i,
         uart_tx_o  => uart_tx_o,
         rx_ready_i => main_uart_rx_ready,
         rx_valid_o => main_uart_rx_valid,
         rx_data_o  => main_uart_rx_data,
         tx_ready_o => main_uart_tx_ready,
         tx_valid_i => main_uart_tx_valid,
         tx_data_i  => main_uart_tx_data
      ); -- uart_inst

   main_uart_rx_ready <= main_cmd_ready;

   cmd_proc : process (main_clk_i)
   begin
      if rising_edge(main_clk_i) then
         if main_cmd_ready = '1' then
            main_cmd_valid <= '0';
         end if;

         if main_uart_rx_valid = '1' and main_uart_rx_ready = '1' then
            if main_uart_rx_data >= X"61" and main_uart_rx_data <= X"7A" then
               main_cmd_data  <= main_uart_rx_data - X"20";
               main_cmd_valid <= '1';
            else
               main_cmd_data  <= main_uart_rx_data;
               main_cmd_valid <= '1';
            end if;
         end if;

         if main_key_valid = '1' then
            main_cmd_valid <= '1';
            main_cmd_data  <= main_key_data;
         end if;
      end if;
   end process cmd_proc;

   controller_inst : entity work.controller
      generic map (
         G_CELL_BITS => G_CELL_BITS,
         G_STAT_SIZE => G_STAT_SIZE,
         G_ROWS      => G_ROWS,
         G_COLS      => G_COLS
      )
      port map (
         clk_i                => main_clk_i,
         rst_i                => main_rst_i,
         cmd_valid_i          => main_cmd_valid,
         cmd_ready_o          => main_cmd_ready,
         cmd_data_i           => main_cmd_data,
         uart_tx_valid_o      => main_uart_tx_valid,
         uart_tx_ready_i      => main_uart_tx_ready,
         uart_tx_data_o       => main_uart_tx_data,
         init_density_i       => main_init_density_i,
         init_border_i        => main_init_border_i,
         generational_speed_i => main_generational_speed_i,
         ready_i              => main_life_ready_i,
         step_o               => main_life_step_o,
         gens_o               => main_life_gens,
         auto_stop_i          => main_auto_stop_en_i and main_auto_stop,
         main_bottom_i        => main_bottom,
         start_row_o          => main_life_start_row_o,
         start_col_o          => main_life_start_col_o,
         load_o               => main_drives_load,
         save_o               => main_drives_save,
         ack_i                => main_drives_ack,
         board_busy_o         => main_controller_busy,
         board_addr_o         => main_controller_addr,
         board_rd_data_i      => main_board_rd_data_i,
         board_wr_data_o      => main_controller_wr_data,
         board_wr_en_o        => main_controller_wr_en
      ); -- controller_inst

   statistics_inst : entity work.statistics
      generic map (
         G_CELL_BITS => G_CELL_BITS,
         G_STAT_SIZE => G_STAT_SIZE,
         G_ROWS      => G_ROWS,
         G_COLS      => G_COLS
      )
      port map (
         clk_i     => main_clk_i,
         rst_i     => main_rst_i,
         addr_i    => main_board_addr_o,
         wr_data_i => main_board_wr_data_o,
         wr_en_i   => main_board_wr_en_o,
         m_ready_i => and(main_stat_ready),
         m_valid_o => main_stat_valid,
         m_data_o  => main_stat_data
      ); -- statistics_inst

   main_bottom_ready <= and(main_bottom_valid);

   bin2bcd_gens_inst : entity work.bin2bcd
      port map (
         clk_i     => main_clk_i,
         rst_i     => main_rst_i,
         s_ready_o => main_stat_ready(0),
         s_valid_i => main_stat_valid and (and(main_stat_ready)),
         s_data_i  => main_life_gens,
         m_ready_i => main_bottom_ready,
         m_valid_o => main_bottom_valid(0),
         m_data_o  => main_bottom(79 downto 0)
      ); -- bin2bcd_gens_inst

   stat_gen : for i in 0 to G_STAT_SIZE - 1 generate

      bin2bcd_count_inst : entity work.bin2bcd
         port map (
            clk_i     => main_clk_i,
            rst_i     => main_rst_i,
            s_ready_o => main_stat_ready(i + 1),
            s_valid_i => main_stat_valid and (and(main_stat_ready)),
            s_data_i  => main_stat_data(16 * i + 15 downto 16 * i),
            m_ready_i => main_bottom_ready,
            m_valid_o => main_bottom_valid(i + 1),
            m_data_o  => main_bottom(80 * (i + 1) + 79 downto 80 * (i + 1))
         ); -- bin2bcd_count_inst

   end generate stat_gen;

   main_bottom_proc : process (main_clk_i)
   begin
      if rising_edge(main_clk_i) then
         if and (main_bottom_valid) = '1' then
            main_bottom_o  <= main_bottom;
            main_bottom_d  <= main_bottom_o;
            main_bottom_dd <= main_bottom_d;
         end if;
      end if;
   end process main_bottom_proc;

   autostop_proc : process (main_clk_i)
   begin
      if rising_edge(main_clk_i) then
         main_auto_stop <= '0';
         if (main_bottom_o(159 downto 80) = main_bottom_d(159 downto 80)) and
            main_bottom_o(80 * (G_STAT_SIZE + 1) - 1 downto 80) = main_bottom_dd(80 * (G_STAT_SIZE + 1) - 1 downto 80) then
            main_auto_stop <= '1';
         end if;
      end if;
   end process autostop_proc;

   drives_inst : entity work.drives
      generic map (
         G_CELL_BITS => G_CELL_BITS,
         G_ROWS      => G_ROWS,
         G_COLS      => G_COLS
      )
      port map (
         main_clk_i     => main_clk_i,
         main_rst_i     => main_rst_i,
         main_load_i    => main_drives_load,
         main_save_i    => main_drives_save,
         main_ack_o     => main_drives_ack,
         main_busy_o    => main_drives_busy,
         main_addr_o    => main_drives_addr,
         main_rd_data_i => main_board_rd_data_i,
         main_wr_data_o => main_drives_wr_data,
         main_wr_en_o   => main_drives_wr_en,
         qnice_clk_i    => qnice_clk_i,
         qnice_rst_i    => qnice_rst_i,
         qnice_addr_i   => qnice_addr_i,
         qnice_data_i   => qnice_data_i,
         qnice_data_o   => qnice_data_o,
         qnice_ce_i     => qnice_ce_i,
         qnice_we_i     => qnice_we_i
      ); -- drives_inst

end architecture synthesis;

