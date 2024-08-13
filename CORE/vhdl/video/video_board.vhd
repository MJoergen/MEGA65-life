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
      video_x_i         : in    std_logic_vector(7 downto 0);
      video_y_i         : in    std_logic_vector(7 downto 0);
      video_bottom_i    : in    std_logic_vector(80 * (G_STAT_SIZE + 1) - 1 downto 0);
      video_start_row_i : in    natural range 0 to G_ROWS - 1;
      video_start_col_i : in    natural range 0 to G_COLS - 1;
      video_addr_o      : out   std_logic_vector(9 downto 0);
      video_data_i      : in    std_logic_vector(G_CELL_BITS * G_COLS - 1 downto 0);
      video_char_o      : out   std_logic_vector(7 downto 0);
      video_colors_o    : out   std_logic_vector(15 downto 0)
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
      if get_start_y + G_ROWS - 1 < G_VIDEO_MODE.V_PIXELS / 8 then
         return get_start_y + G_ROWS - 1;
      else
         return G_VIDEO_MODE.V_PIXELS / 8;
      end if;
   end function get_end_y;

   constant C_START_X : std_logic_vector(7 downto 0)     := to_stdlogicvector(get_start_x, 8);
   constant C_START_Y : std_logic_vector(7 downto 0)     := to_stdlogicvector(get_start_y, 8);
   constant C_END_X   : std_logic_vector(7 downto 0)     := to_stdlogicvector(get_end_x, 8);
   constant C_END_Y   : std_logic_vector(7 downto 0)     := to_stdlogicvector(get_end_y, 8);

   signal   video_board_x : natural range 0 to G_COLS - 1;
   signal   video_board_y : natural range 0 to G_ROWS - 1;

begin

   video_pan_proc : process (all)
      variable tmp_x_v : natural range 0 to G_COLS - 1;
      variable tmp_y_v : natural range 0 to G_ROWS - 1;
   begin
      tmp_x_v := to_integer(video_x_i - C_START_X);
      tmp_y_v := to_integer(video_y_i - C_START_Y);

      if tmp_x_v + video_start_col_i < G_COLS then
         video_board_x <= tmp_x_v + video_start_col_i;
      else
         video_board_x <= tmp_x_v + video_start_col_i  - G_COLS;
      end if;

      if tmp_y_v + video_start_row_i < G_ROWS then
         video_board_y <= tmp_y_v + video_start_row_i;
      else
         video_board_y <= tmp_y_v + video_start_row_i - G_ROWS;
      end if;
   end process video_pan_proc;


   video_addr_o <= to_stdlogicvector(video_board_y, 10);

   char_proc : process (video_clk_i)
      variable video_dec_index_v : natural range 0 to 4;
      variable cell_v            : std_logic_vector(G_CELL_BITS - 1 downto 0);
   begin
      if rising_edge(video_clk_i) then
         video_colors_o <= C_PIXEL_GREY & C_PIXEL_GREY;
         video_char_o   <= X"20";

         -- Display board
         if video_x_i >= C_START_X and video_x_i < C_END_X and
            video_y_i >= C_START_Y and video_y_i < C_END_Y then
            cell_v := video_data_i((video_board_x + 1) * G_CELL_BITS - 1 downto video_board_x * G_CELL_BITS);
            if or (cell_v) = '1' then
               video_char_o <= X"58";
            else
               video_char_o <= X"2E";
            end if;
            video_colors_o <= C_PIXEL_DARK & (C_PIXEL_LIGHT / (2 ** G_CELL_BITS - to_integer(cell_v)));
         end if;

         -- Display bottom line
         if video_x_i >= C_START_X and video_x_i < C_START_X + 10 * (G_STAT_SIZE + 1) and
            video_y_i = C_END_Y then
            video_dec_index_v := to_integer(video_x_i - C_START_X);
            video_char_o      <= video_bottom_i(8 * video_dec_index_v + 7 downto 8 * video_dec_index_v);
            video_colors_o    <= C_PIXEL_DARK & C_PIXEL_LIGHT;
         end if;
         if video_x_i >= C_START_X + 10 * (G_STAT_SIZE + 1) and video_x_i < C_START_X + G_COLS and
            video_y_i = C_END_Y then
            video_colors_o <= C_PIXEL_DARK & C_PIXEL_LIGHT;
         end if;
      end if;
   end process char_proc;

end architecture synthesis;

