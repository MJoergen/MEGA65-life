----------------------------------------------------------------------------------
-- Wrapper for the handling of disk images
--
-- Done by MJoergen in 2024 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library work;
   use work.vdrives_pkg.all;

library xpm;
   use xpm.vcomponents.all;

entity drives is
   generic (
      G_CELL_BITS : natural;
      G_ROWS      : integer;
      G_COLS      : integer
   );
   port (
      main_clk_i     : in    std_logic;
      main_rst_i     : in    std_logic;
      main_load_i    : in    std_logic;
      main_save_i    : in    std_logic;
      main_ack_o     : out   std_logic;
      main_busy_o    : out   std_logic;
      main_addr_o    : out   std_logic_vector(9 downto 0);
      main_rd_data_i : in    std_logic_vector(G_CELL_BITS * G_COLS - 1 downto 0);
      main_wr_data_o : out   std_logic_vector(G_CELL_BITS * G_COLS - 1 downto 0);
      main_wr_en_o   : out   std_logic;

      qnice_clk_i    : in    std_logic;
      qnice_rst_i    : in    std_logic;
      qnice_addr_i   : in    std_logic_vector(27 downto 0);
      qnice_data_i   : in    std_logic_vector(15 downto 0);
      qnice_data_o   : out   std_logic_vector(15 downto 0);
      qnice_ce_i     : in    std_logic;
      qnice_we_i     : in    std_logic
   );
end entity drives;

architecture synthesis of drives is

   type   main_state_type is (IDLE_ST, WAIT_ST, BUSY_ST, PAUSE_ST);
   signal main_state : main_state_type   := IDLE_ST;

   signal main_sd_lba       : std_logic_vector(31 downto 0);
   signal main_sd_rd        : std_logic;
   signal main_sd_wr        : std_logic;
   signal main_sd_ack       : std_logic;
   signal main_sd_buff_addr : std_logic_vector(AW downto 0);
   signal main_sd_buff_dout : std_logic_vector(DW downto 0);
   signal main_sd_buff_din  : std_logic_vector(DW downto 0);
   signal main_sd_buff_wr   : std_logic;
   signal main_saving       : std_logic;

   signal main_img_mounted     : std_logic_vector(0 downto 0);
   signal main_img_readonly    : std_logic;
   signal main_img_size        : std_logic_vector(31 downto 0);
   signal main_img_type        : std_logic_vector(1 downto 0);
   signal main_drive_mounted   : std_logic_vector(0 downto 0);
   signal main_cache_dirty     : std_logic_vector(0 downto 0);
   signal main_cache_flushing  : std_logic_vector(0 downto 0);

   signal qnice2main_in  : std_logic_vector(AW + DW + 3 downto 0);
   signal qnice2main_out : std_logic_vector(AW + DW + 3 downto 0);
   signal main2qnice_in  : std_logic_vector(DW + 34 downto 0);
   signal main2qnice_out : std_logic_vector(DW + 34 downto 0);

   signal main_index_d : natural range 0 to 1023;

   signal qnice_sd_lba         : std_logic_vector(31 downto 0);
   signal qnice_sd_rd          : std_logic;
   signal qnice_sd_wr          : std_logic;
   signal qnice_sd_ack         : std_logic;
   signal qnice_sd_buff_addr   : std_logic_vector(AW downto 0);
   signal qnice_sd_buff_dout   : std_logic_vector(DW downto 0);
   signal qnice_sd_buff_din    : std_logic_vector(DW downto 0);
   signal qnice_sd_buff_wr     : std_logic;

begin

   ------------------------------------------------
   -- State machine
   ------------------------------------------------

   main_addr_o <= main_sd_lba(9 downto 0);

   main_busy_o <= '1' when main_state /= IDLE_ST else '0';

   fsm_main_proc : process (main_clk_i)
   begin
      if rising_edge(main_clk_i) then
         main_ack_o <= '0';
         if main_sd_ack = '1' then
            main_sd_rd <= '0';
            main_sd_wr <= '0';
         end if;

         case main_state is

            when IDLE_ST =>
               if main_load_i = '1' then
                  main_sd_rd  <= '1';
                  main_sd_lba <= (others => '0');
                  main_saving <= '0';
                  main_state  <= WAIT_ST;
               end if;

               if main_save_i = '1' then
                  main_sd_wr  <= '1';
                  main_sd_lba <= (others => '0');
                  main_saving <= '1';
                  main_state  <= WAIT_ST;
               end if;

            when WAIT_ST =>
               if main_sd_ack = '1' then
                  main_state <= BUSY_ST;
               end if;

            when BUSY_ST =>
               if main_sd_ack = '0' then
                  if main_sd_lba < G_ROWS-1 then
                     main_sd_lba <= main_sd_lba + 1;
                     main_state  <= PAUSE_ST;
                  else
                     main_ack_o <= '1';
                     main_state <= IDLE_ST;
                  end if;
               end if;

            when PAUSE_ST =>
               main_sd_rd <= not main_saving;
               main_sd_wr <= main_saving;
               main_state <= WAIT_ST;

         end case;

         if main_rst_i = '1' then
            main_sd_rd  <= '0';
            main_sd_wr  <= '0';
            main_saving <= '0';
            main_state  <= IDLE_ST;
         end if;
      end if;
   end process fsm_main_proc;

   load_proc : process (main_clk_i)
      variable index_v : natural range 0 to 1023;
   begin
      if rising_edge(main_clk_i) then
         main_wr_en_o <= '0';
         index_v    := to_integer(main_sd_buff_addr);
         main_index_d <= index_v;
         main_sd_buff_din <= (others => '0');
         main_sd_buff_din(G_CELL_BITS-1 downto 0) <= main_rd_data_i(index_v * G_CELL_BITS + G_CELL_BITS - 1 downto index_v * G_CELL_BITS);
         if index_v <= G_COLS - 1 then
            main_wr_data_o(index_v * G_CELL_BITS + G_CELL_BITS - 1 downto index_v * G_CELL_BITS) <= main_sd_buff_dout(G_CELL_BITS - 1 downto 0);
         end if;
         if main_index_d /= G_COLS and index_v = G_COLS and main_saving = '0' then
            main_wr_en_o <= '1';
         end if;
      end if;
   end process load_proc;


   ------------------------------------------------
   -- Clock Domain Crossings
   ------------------------------------------------

   qnice2main_in    <=
   (
      qnice_sd_buff_addr,
      qnice_sd_buff_dout,
      qnice_sd_buff_wr,
      qnice_sd_ack
   );

   (main_sd_buff_addr,
   main_sd_buff_dout,
   main_sd_buff_wr,
   main_sd_ack) <= qnice2main_out;

   qnice2main_inst : component xpm_cdc_array_single
      generic map (
         DEST_SYNC_FF => 2,
         WIDTH        => AW + DW + 4
      )
      port map (
         src_clk  => qnice_clk_i,
         src_in   => qnice2main_in,
         dest_clk => main_clk_i,
         dest_out => qnice2main_out
      ); -- qnice2main_inst

   main2qnice_in <=
   (
      main_sd_buff_din,
      main_sd_rd,
      main_sd_wr,
      main_sd_lba
   );

   (qnice_sd_buff_din,
   qnice_sd_rd,
   qnice_sd_wr,
   qnice_sd_lba) <= main2qnice_out;

   main2qnice_inst : component xpm_cdc_array_single
      generic map (
         DEST_SYNC_FF => 2,
         WIDTH        => DW + 35
      )
      port map (
         src_clk  => main_clk_i,
         src_in   => main2qnice_in,
         dest_clk => qnice_clk_i,
         dest_out => main2qnice_out
      ); -- main2qnice_inst


   ------------------------------------------------
   -- Interface to M2M framework
   ------------------------------------------------

   vdrives_inst : entity work.vdrives
      generic map (
         VDNUM => 1,
         BLKSZ => 2 -- block size = 512
      )
      port map (
         clk_core_i       => main_clk_i,
         reset_core_i     => main_rst_i,
         img_mounted_o    => main_img_mounted,
         img_readonly_o   => main_img_readonly,
         img_size_o       => main_img_size,
         img_type_o       => main_img_type,
         drive_mounted_o  => main_drive_mounted,
         cache_dirty_o    => main_cache_dirty,
         cache_flushing_o => main_cache_flushing,
         clk_qnice_i      => qnice_clk_i,
         sd_lba_i(0)      => qnice_sd_lba,       -- units of 512 bytes
         sd_blk_cnt_i(0)  => "000000",           -- One sector at a time
         sd_rd_i(0)       => qnice_sd_rd,
         sd_wr_i(0)       => qnice_sd_wr,
         sd_ack_o(0)      => qnice_sd_ack,
         sd_buff_addr_o   => qnice_sd_buff_addr, -- RAM interface (1 cycle latency)
         sd_buff_dout_o   => qnice_sd_buff_dout,
         sd_buff_din_i(0) => qnice_sd_buff_din,
         sd_buff_wr_o     => qnice_sd_buff_wr,
         qnice_addr_i     => qnice_addr_i,
         qnice_data_i     => qnice_data_i,
         qnice_data_o     => qnice_data_o,
         qnice_ce_i       => qnice_ce_i,
         qnice_we_i       => qnice_we_i
      ); -- vdrives_inst

end architecture synthesis;

