library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity statistics is
   generic (
      G_CELL_BITS : natural;
      G_STAT_SIZE : natural;
      G_ROWS      : integer;
      G_COLS      : integer
   );
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;
      addr_i    : in    std_logic_vector(9 downto 0);
      wr_data_i : in    std_logic_vector(G_CELL_BITS * G_COLS - 1 downto 0);
      wr_en_i   : in    std_logic;
      m_ready_i : in    std_logic;
      m_valid_o : out   std_logic;
      m_data_o  : out   std_logic_vector(16 * G_STAT_SIZE - 1 downto 0)
   );
end entity statistics;

architecture synthesis of statistics is

   -- This calculation is pipelined to improve timing.

   signal stage1_wr_en          : std_logic;
   signal stage1_first_row      : std_logic;
   signal stage1_last_row       : std_logic;
   signal stage1_row_cells      : std_logic_vector(G_COLS - 1 downto 0);
   signal stage1_cell_count_row : std_logic_vector(16 * G_STAT_SIZE - 1 downto 0);

   signal stage2_wr_en          : std_logic;
   signal stage2_first_row      : std_logic;
   signal stage2_last_row       : std_logic;
   signal stage2_cell_count_row : std_logic_vector(16 * G_STAT_SIZE - 1 downto 0);

   signal stage3_wr_en    : std_logic;
   signal stage3_last_row : std_logic;

   signal total : std_logic_vector(16 * G_STAT_SIZE - 1 downto 0);

   pure function get_row_cells (
      arg : std_logic_vector
   ) return std_logic_vector is
      variable res_v  : std_logic_vector(G_COLS - 1 downto 0);
      variable cell_v : std_logic_vector(G_CELL_BITS - 1 downto 0);
   begin
      --
      for i in 0 to G_COLS - 1 loop
         cell_v   := arg((i + 1) * G_CELL_BITS - 1 downto i * G_CELL_BITS);
         res_v(i) := or(cell_v);
      end loop;

      return res_v;
   end function get_row_cells;

   pure function rotate (
      arg : std_logic_vector;
      shift : natural
   ) return std_logic_vector
   is
   begin
      return arg(arg'left-shift downto 0) & arg(arg'left downto arg'left-shift + 1);
   end function rotate;

begin

   -- Stage 1 : Get new row
   stage1_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         stage1_wr_en     <= wr_en_i;
         stage1_first_row <= '0';
         stage1_last_row  <= '0';

         if wr_en_i = '1' then
            stage1_row_cells(G_COLS - 1 downto 0) <= get_row_cells(wr_data_i);

            if addr_i = 0 then
               stage1_first_row <= '1';
            end if;
            if addr_i = G_ROWS - 1 then
               stage1_last_row <= '1';
            end if;
         end if;
      end if;
   end process stage1_proc;

   count_ones_gen : for i in 0 to G_STAT_SIZE - 1 generate

      count_ones_inst : entity work.count_ones
         generic map (
            G_DATA_SIZE => G_COLS
         )
         port map (
            clk_i   => clk_i,
            rst_i   => rst_i,
            data_i  => rotate(stage1_row_cells, i) and stage1_row_cells,
            total_o => stage1_cell_count_row(i * 16 + 15 downto i * 16)
         ); -- count_ones_inst

   end generate count_ones_gen;

   -- Stage 2 : Count number of cells in row
   stage2_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         stage2_wr_en     <= stage1_wr_en;
         stage2_first_row <= stage1_first_row;
         stage2_last_row  <= stage1_last_row;

         if stage1_wr_en = '1' then
            stage2_cell_count_row <= stage1_cell_count_row;
         end if;
      end if;
   end process stage2_proc;

   -- Stage 3 : Update total count
   stage3_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         stage3_wr_en    <= stage2_wr_en;
         stage3_last_row <= stage2_last_row;

         if stage2_wr_en = '1' then
            if stage2_first_row = '1' then
               total <= stage2_cell_count_row;
            else

               for i in 0 to G_STAT_SIZE - 1 loop
                  total(i * 16 + 15 downto i * 16) <= total(i * 16 + 15 downto i * 16) + stage2_cell_count_row(i * 16 + 15 downto i * 16);
               end loop;

            end if;
         end if;
      end if;
   end process stage3_proc;

   -- Stage 4 : Update output
   stage4_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if m_ready_i = '1' then
            m_valid_o <= '0';
         end if;
         if stage3_last_row = '1' then
            m_data_o  <= total;
            m_valid_o <= '1';
         end if;

         if rst_i = '1' then
            m_valid_o <= '0';
         end if;
      end if;
   end process stage4_proc;

end architecture synthesis;

