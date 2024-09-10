library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

library work;
   use work.video_modes_pkg.all;

entity video_wrapper is
   generic (
      G_VIDEO_MODE : video_modes_t;
      G_FONT_PATH  : string := "";
      G_CELL_BITS  : integer;
      G_STAT_SIZE  : integer;
      G_ROWS       : integer;
      G_COLS       : integer
   );
   port (
      video_clk_i       : in    std_logic;
      video_rst_i       : in    std_logic;
      video_bottom_i    : in    std_logic_vector(80 * (G_STAT_SIZE + 1) - 1 downto 0);
      video_start_row_i : in    natural range 0 to G_ROWS - 1;
      video_start_col_i : in    natural range 0 to G_COLS - 1;
      video_addr_o      : out   std_logic_vector(9 downto 0);
      video_data_i      : in    std_logic_vector(G_CELL_BITS * G_COLS - 1 downto 0);

      video_ce_o        : out   std_logic;
      video_ce_ovl_o    : out   std_logic;
      video_red_o       : out   std_logic_vector(7 downto 0);
      video_green_o     : out   std_logic_vector(7 downto 0);
      video_blue_o      : out   std_logic_vector(7 downto 0);
      video_vs_o        : out   std_logic;
      video_hs_o        : out   std_logic;
      video_hblank_o    : out   std_logic;
      video_vblank_o    : out   std_logic
   );
end entity video_wrapper;

architecture synthesis of video_wrapper is

   signal column : integer range 0 to 2047;
   signal row    : integer range 0 to 2047;

   signal video_hs     : std_logic;
   signal video_vs     : std_logic;
   signal video_hblank : std_logic;
   signal video_vblank : std_logic;
   signal video_pix_x  : std_logic_vector(10 downto 0);
   signal video_pix_y  : std_logic_vector(10 downto 0);
   signal video_rgb    : std_logic_vector(23 downto 0);

   signal video_board_hs     : std_logic;
   signal video_board_vs     : std_logic;
   signal video_board_hblank : std_logic;
   signal video_board_vblank : std_logic;
   signal video_board_pix_x  : std_logic_vector(10 downto 0);
   signal video_board_pix_y  : std_logic_vector(10 downto 0);
   signal video_board_rgb    : std_logic_vector(23 downto 0);

   signal video_stats_rgb : std_logic_vector(23 downto 0);

begin

   vga_controller_inst : entity work.vga_controller
      port map (
         clk_i    => video_clk_i,
         ce_i     => '1',
         reset_n  => not video_rst_i,
         h_pulse  => G_VIDEO_MODE.H_PULSE,
         h_bp     => G_VIDEO_MODE.H_BP,
         h_pixels => G_VIDEO_MODE.H_PIXELS,
         h_fp     => G_VIDEO_MODE.H_FP,
         h_pol    => '1',
         v_pulse  => G_VIDEO_MODE.V_PULSE,
         v_bp     => G_VIDEO_MODE.V_BP,
         v_pixels => G_VIDEO_MODE.V_PIXELS,
         v_fp     => G_VIDEO_MODE.V_FP,
         v_pol    => '1',
         h_sync   => video_hs,
         v_sync   => video_vs,
         h_blank  => video_hblank,
         v_blank  => video_vblank,
         column   => column,
         row      => row,
         n_blank  => open,
         n_sync   => open
      ); -- vga_controller_inst

   video_pix_x <= std_logic_vector(to_unsigned(column, 11));
   video_pix_y <= std_logic_vector(to_unsigned(row, 11));

   video_board_inst : entity work.video_board
      generic map (
         G_VIDEO_MODE => G_VIDEO_MODE,
         G_CELL_BITS  => G_CELL_BITS,
         G_STAT_SIZE  => G_STAT_SIZE,
         G_ROWS       => G_ROWS,
         G_COLS       => G_COLS
      )
      port map (
         video_clk_i       => video_clk_i,
         video_rst_i       => video_rst_i,
         video_start_row_i => video_start_row_i,
         video_start_col_i => video_start_col_i,
         video_addr_o      => video_addr_o,
         video_data_i      => video_data_i,

         video_hs_i        => video_hs,
         video_vs_i        => video_vs,
         video_hblank_i    => video_hblank,
         video_vblank_i    => video_vblank,
         video_pix_x_i     => video_pix_x,
         video_pix_y_i     => video_pix_y,
         video_rgb_i       => (others => '0'),

         video_hs_o        => video_board_hs,
         video_vs_o        => video_board_vs,
         video_hblank_o    => video_board_hblank,
         video_vblank_o    => video_board_vblank,
         video_pix_x_o     => video_board_pix_x,
         video_pix_y_o     => video_board_pix_y,
         video_rgb_o       => video_board_rgb
      ); -- video_board_inst


   video_stats_inst : entity work.video_stats
      generic map (
         G_VIDEO_MODE => G_VIDEO_MODE,
         G_FONT_FILE  => G_FONT_PATH & "font8x8.txt",
         G_STAT_SIZE  => G_STAT_SIZE
      )
      port map (
         video_clk_i    => video_clk_i,
         video_rst_i    => video_rst_i,
         video_bottom_i => video_bottom_i,

         video_hs_i     => video_board_hs,
         video_vs_i     => video_board_vs,
         video_hblank_i => video_board_hblank,
         video_vblank_i => video_board_vblank,
         video_pix_x_i  => video_board_pix_x,
         video_pix_y_i  => video_board_pix_y,
         video_rgb_i    => video_board_rgb,

         video_hs_o     => video_hs_o,
         video_vs_o     => video_vs_o,
         video_hblank_o => video_hblank_o,
         video_vblank_o => video_vblank_o,
         video_pix_x_o  => open,
         video_pix_y_o  => open,
         video_rgb_o    => video_stats_rgb
      ); -- video_stats_inst

   (video_red_o, video_green_o, video_blue_o) <= video_stats_rgb;

   video_ce_o                                 <= '1';
   video_ce_ovl_o                             <= '1';

end architecture synthesis;

