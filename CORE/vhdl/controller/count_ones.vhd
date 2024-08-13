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

begin

   total_o <= to_stdlogicvector(count_ones_func(data_i), 16);

end architecture synthesis;

