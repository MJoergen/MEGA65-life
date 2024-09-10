library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library work;
   use work.video_modes_pkg.all;

entity video_stats is
   generic (
      G_VIDEO_MODE : video_modes_t;
      G_FONT_FILE  : string;
      G_STAT_SIZE  : integer
   );
   port (
      video_clk_i    : in    std_logic;
      video_rst_i    : in    std_logic;
      video_bottom_i : in    std_logic_vector(80 * (G_STAT_SIZE + 1) - 1 downto 0);

      -- Input video stream
      video_hs_i     : in    std_logic;
      video_vs_i     : in    std_logic;
      video_hblank_i : in    std_logic;
      video_vblank_i : in    std_logic;
      video_pix_x_i  : in    std_logic_vector(10 downto 0);
      video_pix_y_i  : in    std_logic_vector(10 downto 0);
      video_rgb_i    : in    std_logic_vector(23 downto 0);

      -- Output video stream
      video_hs_o     : out   std_logic;
      video_vs_o     : out   std_logic;
      video_hblank_o : out   std_logic;
      video_vblank_o : out   std_logic;
      video_pix_x_o  : out   std_logic_vector(10 downto 0);
      video_pix_y_o  : out   std_logic_vector(10 downto 0);
      video_rgb_o    : out   std_logic_vector(23 downto 0)
   );
end entity video_stats;

architecture synthesis of video_stats is

   -- Define colours
   constant C_PIXEL_DARK  : std_logic_vector(7 downto 0) := B"001_001_01";
   constant C_PIXEL_GREY  : std_logic_vector(7 downto 0) := B"010_010_01";
   constant C_PIXEL_LIGHT : std_logic_vector(7 downto 0) := B"100_100_10";

   constant C_END_X : std_logic_vector(10 downto 0)      := to_stdlogicvector(80 * (G_STAT_SIZE + 1), 11);
   constant C_END_Y : std_logic_vector(10 downto 0)      := to_stdlogicvector(G_VIDEO_MODE.V_PIXELS - 8, 11);

   signal   video_bottom_index_0 : natural range 0 to 10 * (G_STAT_SIZE + 1) - 1;
   signal   video_char_0         : std_logic_vector(7 downto 0);
   signal   video_bitmap_index_0 : integer range 0 to 63;
   signal   video_pix_col_0      : integer range 0 to 7;
   signal   video_pix_row_0      : integer range 0 to 7;

   signal   video_bitmap_index_1 : integer range 0 to 63;
   signal   video_colors_1 : std_logic_vector(15 downto 0);
   signal   video_bitmap_1 : std_logic_vector(63 downto 0);
   signal   video_hs_1     : std_logic;
   signal   video_vs_1     : std_logic;
   signal   video_hblank_1 : std_logic;
   signal   video_vblank_1 : std_logic;
   signal   video_pix_x_1  : std_logic_vector(10 downto 0);
   signal   video_pix_y_1  : std_logic_vector(10 downto 0);
   signal   video_rgb_1    : std_logic_vector(23 downto 0);

begin

   -- Stage 0

   video_bottom_index_0 <= to_integer(video_pix_x_i(10 downto 3));
   video_char_0         <= video_bottom_i(8 * video_bottom_index_0 + 7 downto 8 * video_bottom_index_0);
   video_pix_col_0      <= to_integer(video_pix_x_i(2 downto 0));
   video_pix_row_0      <= 7 - to_integer(video_pix_y_i(2 downto 0));
   video_bitmap_index_0 <= video_pix_row_0 * 8 + video_pix_col_0;

   -- Stage 1

   font_inst : entity work.font
      generic map (
         G_FONT_FILE => G_FONT_FILE
      )
      port map (
         clk_i    => video_clk_i,
         char_i   => video_char_0,
         bitmap_o => video_bitmap_1
      ); -- font_inst

   stage1_proc : process (video_clk_i)
   begin
      if rising_edge(video_clk_i) then
         video_hs_1     <= video_hs_i;
         video_vs_1     <= video_vs_i;
         video_hblank_1 <= video_hblank_i;
         video_vblank_1 <= video_vblank_i;
         video_pix_x_1  <= video_pix_x_i;
         video_pix_y_1  <= video_pix_y_i;
         video_rgb_1    <= video_rgb_i;

         video_bitmap_index_1 <= video_bitmap_index_0;

         video_colors_1 <= C_PIXEL_GREY & C_PIXEL_GREY;
         if video_pix_y_i(10 downto 3) = C_END_Y(10 downto 3) then
            video_colors_1 <= C_PIXEL_DARK & C_PIXEL_LIGHT;
         end if;
      end if;
   end process stage1_proc;

   -- Stage 2

   stage2_proc : process (video_clk_i)
   begin
      if rising_edge(video_clk_i) then
         video_hs_o     <= video_hs_1;
         video_vs_o     <= video_vs_1;
         video_hblank_o <= video_hblank_1;
         video_vblank_o <= video_vblank_1;
         video_pix_x_o  <= video_pix_x_1;
         video_pix_y_o  <= video_pix_y_1;
         video_rgb_o    <= video_rgb_1;

         if video_pix_y_1(10 downto 3) = C_END_Y(10 downto 3) and
            video_pix_x_1 < C_END_X then
            if video_bitmap_1(video_bitmap_index_1) = '1' then
               video_rgb_o(23 downto 16) <= video_colors_1(7 downto 5) & "00000";
               video_rgb_o(15 downto 8)  <= video_colors_1(4 downto 2) & "00000";
               video_rgb_o(7 downto 0)   <= video_colors_1(1 downto 0) & "000000";
            else
               video_rgb_o(23 downto 16) <= video_colors_1(8+7 downto 8+5) & "00000";
               video_rgb_o(15 downto 8)  <= video_colors_1(8+4 downto 8+2) & "00000";
               video_rgb_o(7 downto 0)   <= video_colors_1(8+1 downto 8+0) & "000000";
            end if;
         end if;

      end if;
   end process stage2_proc;

end architecture synthesis;

