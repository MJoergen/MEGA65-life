library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library work;
   use work.video_modes_pkg.all;

entity video_board is
   generic (
      G_VIDEO_MODE : video_modes_t;
      G_CELL_BITS  : integer;
      G_STAT_SIZE  : integer;
      G_ROWS       : integer;
      G_COLS       : integer
   );
   port (
      video_clk_i       : in    std_logic;
      video_rst_i       : in    std_logic;
      video_start_row_i : in    natural range 0 to G_ROWS - 1;
      video_start_col_i : in    natural range 0 to G_COLS - 1;
      video_addr_o      : out   std_logic_vector(9 downto 0);
      video_data_i      : in    std_logic_vector(G_CELL_BITS * G_COLS - 1 downto 0);

      -- Input video stream
      video_hs_i        : in    std_logic;
      video_vs_i        : in    std_logic;
      video_hblank_i    : in    std_logic;
      video_vblank_i    : in    std_logic;
      video_pix_x_i     : in    std_logic_vector(10 downto 0);
      video_pix_y_i     : in    std_logic_vector(10 downto 0);
      video_rgb_i       : in    std_logic_vector(23 downto 0);

      -- Output video stream
      video_hs_o        : out   std_logic;
      video_vs_o        : out   std_logic;
      video_hblank_o    : out   std_logic;
      video_vblank_o    : out   std_logic;
      video_pix_x_o     : out   std_logic_vector(10 downto 0);
      video_pix_y_o     : out   std_logic_vector(10 downto 0);
      video_rgb_o       : out   std_logic_vector(23 downto 0)
   );
end entity video_board;

architecture synthesis of video_board is

   -- Define colours
   constant C_PIXEL_DARK  : std_logic_vector(7 downto 0) := B"001_001_01";
   constant C_PIXEL_GREY  : std_logic_vector(7 downto 0) := B"010_010_01";
   constant C_PIXEL_LIGHT : std_logic_vector(7 downto 0) := B"100_100_10";

   function get_start_x return natural is
   begin
      if G_VIDEO_MODE.H_PIXELS / 16 >= (G_COLS + 1) / 2 then
         return G_VIDEO_MODE.H_PIXELS / 16 - (G_COLS + 1) / 2;
      else
         return 0;
      end if;
   end function get_start_x;

   function get_start_y return natural is
   begin
      if G_VIDEO_MODE.V_PIXELS / 16 >= (G_ROWS + 1) / 2 then
         return G_VIDEO_MODE.V_PIXELS / 16 - (G_ROWS + 1) / 2;
      else
         return 0;
      end if;
   end function get_start_y;

   function get_end_x return natural is
   begin
      if get_start_x + G_COLS < G_VIDEO_MODE.H_PIXELS / 8 then
         return get_start_x + G_COLS;
      else
         return G_VIDEO_MODE.H_PIXELS / 8;
      end if;
   end function get_end_x;

   function get_end_y return natural is
   begin
      if get_start_y + G_ROWS < G_VIDEO_MODE.V_PIXELS / 8 - 1 then
         return get_start_y + G_ROWS;
      else
         return G_VIDEO_MODE.V_PIXELS / 8 - 1;
      end if;
   end function get_end_y;

   pure function get_color (
      age : natural range 0 to 2**G_CELL_BITS-1
   ) return std_logic_vector is
      variable col_v : std_logic_vector(7 downto 0);
   begin
      col_v := C_PIXEL_LIGHT / (2 ** G_CELL_BITS - age);
      return col_v(7 downto 5) & "00000" &
             col_v(4 downto 2) & "00000" &
             col_v(1 downto 0) & "000000";
   end function get_color;

   constant C_START_X : std_logic_vector(10 downto 0)    := to_stdlogicvector(8 * get_start_x, 11);
   constant C_START_Y : std_logic_vector(10 downto 0)    := to_stdlogicvector(8 * get_start_y, 11);
   constant C_END_X   : std_logic_vector(10 downto 0)    := to_stdlogicvector(8 * get_end_x, 11);
   constant C_END_Y   : std_logic_vector(10 downto 0)    := to_stdlogicvector(8 * get_end_y, 11);

   -- Stage 1
   signal   video_board_x_1 : natural range 0 to G_COLS - 1;
   signal   video_board_y_1 : natural range 0 to G_ROWS - 1;
   signal   video_hs_1      : std_logic;
   signal   video_vs_1      : std_logic;
   signal   video_hblank_1  : std_logic;
   signal   video_vblank_1  : std_logic;
   signal   video_pix_x_1   : std_logic_vector(10 downto 0);
   signal   video_pix_y_1   : std_logic_vector(10 downto 0);
   signal   video_rgb_1     : std_logic_vector(23 downto 0);

   -- Stage 2
   signal   video_board_x_2 : natural range 0 to G_COLS - 1;
   signal   cell_2          : std_logic_vector(G_CELL_BITS - 1 downto 0);
   signal   video_hs_2      : std_logic;
   signal   video_vs_2      : std_logic;
   signal   video_hblank_2  : std_logic;
   signal   video_vblank_2  : std_logic;
   signal   video_pix_x_2   : std_logic_vector(10 downto 0);
   signal   video_pix_y_2   : std_logic_vector(10 downto 0);
   signal   video_rgb_2     : std_logic_vector(23 downto 0);

begin

   stage1_proc : process (video_clk_i)
      variable tmp_x_v : natural range 0 to G_COLS - 1;
      variable tmp_y_v : natural range 0 to G_ROWS - 1;
   begin
      if rising_edge(video_clk_i) then
         video_hs_1     <= video_hs_i;
         video_vs_1     <= video_vs_i;
         video_hblank_1 <= video_hblank_i;
         video_vblank_1 <= video_vblank_i;
         video_pix_x_1  <= video_pix_x_i;
         video_pix_y_1  <= video_pix_y_i;
         video_rgb_1    <= video_rgb_i;

         tmp_x_v        := to_integer(video_pix_x_i - C_START_X) / 8;
         tmp_y_v        := to_integer(video_pix_y_i - C_START_Y) / 8;

         if tmp_x_v + video_start_col_i < G_COLS then
            video_board_x_1 <= tmp_x_v + video_start_col_i;
         else
            video_board_x_1 <= tmp_x_v + video_start_col_i  - G_COLS;
         end if;

         if tmp_y_v + video_start_row_i < G_ROWS then
            video_board_y_1 <= tmp_y_v + video_start_row_i;
         else
            video_board_y_1 <= tmp_y_v + video_start_row_i - G_ROWS;
         end if;
      end if;
   end process stage1_proc;

   video_addr_o <= to_stdlogicvector(video_board_y_1, 10);

   stage2_proc : process (video_clk_i)
   begin
      if rising_edge(video_clk_i) then
         video_hs_2      <= video_hs_1;
         video_vs_2      <= video_vs_1;
         video_hblank_2  <= video_hblank_1;
         video_vblank_2  <= video_vblank_1;
         video_pix_x_2   <= video_pix_x_1;
         video_pix_y_2   <= video_pix_y_1;
         video_rgb_2     <= video_rgb_1;

         video_board_x_2 <= video_board_x_1;
      end if;
   end process stage2_proc;

   -- Stage 2
   cell_2       <= video_data_i(video_board_x_2 * G_CELL_BITS + G_CELL_BITS - 1 downto video_board_x_2 * G_CELL_BITS);

   -- Stage 3
   stage3_proc : process (video_clk_i)
      variable video_dec_index_v : natural range 0 to 10 * (G_STAT_SIZE + 1) - 1;
      variable cell_v            : std_logic_vector(G_CELL_BITS - 1 downto 0);
   begin
      if rising_edge(video_clk_i) then
         video_hs_o     <= video_hs_2;
         video_vs_o     <= video_vs_2;
         video_hblank_o <= video_hblank_2;
         video_vblank_o <= video_vblank_2;
         video_pix_x_o  <= video_pix_x_2;
         video_pix_y_o  <= video_pix_y_2;
         video_rgb_o    <= video_rgb_2;

         -- Display board
         if video_pix_x_2 >= C_START_X and video_pix_x_2 < C_END_X and
            video_pix_y_2 >= C_START_Y and video_pix_y_2 < C_END_Y then
            if or (cell_2) = '1' then
               video_rgb_o <= get_color(to_integer(cell_2));
            else
               if (video_pix_x_2(2 downto 0) = 3 or video_pix_x_2(2 downto 0) = 4) and
                  (video_pix_y_2(2 downto 0) = 3 or video_pix_y_2(2 downto 0) = 4) then
                  video_rgb_o <= get_color(0);
               else
                  video_rgb_o <= (others => '0');
               end if;
            end if;
         end if;
      end if;
   end process stage3_proc;

end architecture synthesis;

