library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity count_ones is
   generic (
      G_DATA_SIZE : integer
   );
   port (
      clk_i   : in    std_logic;
      rst_i   : in    std_logic;
      data_i  : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      total_o : out   std_logic_vector(15 downto 0)
   );
end entity count_ones;

architecture synthesis of count_ones is

   pure function count_ones_func (
      arg : std_logic_vector
   ) return natural is
      variable res_v : natural range 0 to arg'length;
   begin
      res_v := 0;

      for i in arg'range loop
         if arg(i) = '1' then
            res_v := res_v + 1;
         end if;
      end loop;

      return res_v;
   end function count_ones_func;

   constant C_NUM_PARTIALS : natural := (G_DATA_SIZE + 29) / 30;

   type     sum_vector_type is array (natural range <>) of std_logic_vector(4 downto 0);
   signal   sum_vector   : sum_vector_type(C_NUM_PARTIALS - 1 downto 0);
   signal   sum_vector_d : sum_vector_type(C_NUM_PARTIALS - 1 downto 0);

   signal   data_padded : std_logic_vector(C_NUM_PARTIALS * 30 - 1 downto 0);

begin

   -- Stage 0

   data_padded_proc : process (all)
   begin
      data_padded                           <= (others => '0');
      data_padded(G_DATA_SIZE - 1 downto 0) <= data_i;
   end process data_padded_proc;

   partial_gen : for i in 0 to C_NUM_PARTIALS-1 generate
      sum_vector(i) <= to_stdlogicvector(count_ones_func(data_padded(i * 30 + 29 downto i * 30)), 5);
   end generate partial_gen;


   -- Stage 1

   sum_vector_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         sum_vector_d <= sum_vector;
      end if;
   end process sum_vector_proc;

   total_proc : process (all)
      variable tmp_v : std_logic_vector(15 downto 0);
   begin
      tmp_v := (others => '0');

      for i in 0 to C_NUM_PARTIALS-1 loop
         tmp_v := tmp_v + sum_vector_d(i);
      end loop;

      total_o <= tmp_v;
   end process total_proc;

end architecture synthesis;

