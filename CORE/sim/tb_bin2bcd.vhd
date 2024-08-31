library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity tb_bin2bcd is
end entity tb_bin2bcd;

architecture simulation of tb_bin2bcd is

   -- Clock, reset, and enable
   signal running : std_logic := '1';
   signal rst     : std_logic := '1';
   signal clk     : std_logic := '1';

   signal s_ready : std_logic;
   signal s_valid : std_logic;
   signal s_data  : std_logic_vector(15 downto 0);
   signal m_ready : std_logic;
   signal m_valid : std_logic;
   signal m_data  : std_logic_vector(79 downto 0);

begin

   rst     <= '1', '0' after 100 ns;
   clk     <= running and not clk after 5 ns;

   m_ready <= '1';

   bin2bcd_inst : entity work.bin2bcd
      port map (
         clk_i     => clk,
         rst_i     => rst,
         s_ready_o => s_ready,
         s_valid_i => s_valid,
         s_data_i  => s_data,
         m_ready_i => m_ready,
         m_valid_o => m_valid,
         m_data_o  => m_data
      ); -- bin2bcd_inst

   test_proc : process
      --

      pure function bin2bcd_sim (
         arg : natural
      ) return std_logic_vector is
         variable res_v   : std_logic_vector(79 downto 0);
         variable digit_v : natural;
         variable data_v  : natural;
      begin
         res_v  := X"20202020202020202020";

         data_v := arg;

         digit_loop : for i in 0 to 4 loop
            digit_v                                   := data_v mod 10;
            data_v                                    := data_v / 10;

            res_v((9 - i) * 8 + 7 downto (9 - i) * 8) := X"3" & to_stdlogicvector(digit_v, 4);
            if data_v = 0 then
               exit digit_loop;
            end if;
         end loop digit_loop;

         return res_v;
      end function bin2bcd_sim;

      procedure verify (
         arg : natural
      ) is
         variable exp_v : std_logic_vector(79 downto 0);
      begin
         report "verify: " & to_string(arg);
         s_data  <= to_stdlogicvector(arg, 16);
         s_valid <= '1';
         wait until clk = '1';

         while s_ready = '0' loop
            wait until clk = '1';
         end loop;

         s_data  <= (others => '0');
         s_valid <= '0';

         while m_valid = '0' loop
            wait until clk = '1';
         end loop;

         exp_v := bin2bcd_sim(arg);
         assert m_data = exp_v
            report "Got: " & to_hstring(m_data) & ", expected:" & to_hstring(exp_v);
      end procedure verify;

   --
   begin
      wait until rst = '0';
      wait until clk = '1';
      report "Test started";

      verify(0);
      verify(1);
      verify(4);
      verify(9);
      verify(10);
      verify(11);
      verify(12);
      verify(20);
      verify(21);
      verify(45);
      verify(99);
      verify(100);
      verify(123);
      verify(12345);
      verify(65535);

      report "Test finished";
      wait until clk = '1';
      running <= '0';
      wait;
   end process test_proc;

end architecture simulation;

