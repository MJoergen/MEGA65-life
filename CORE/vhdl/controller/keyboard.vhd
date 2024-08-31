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

entity keyboard is
   generic (
      G_MAIN_CLK_HZ : natural
   );
   port (
      main_clk_i              : in    std_logic;
      main_rst_i              : in    std_logic;
      main_kb_key_num_i       : in    integer range 0 to 79;
      main_kb_key_pressed_n_i : in    std_logic;
      main_key_valid_o        : out   std_logic;
      main_key_data_o         : out   std_logic_vector(7 downto 0)
   );
end entity keyboard;

architecture synthesis of keyboard is

   -- MEGA65 key codes that kb_key_num_i is using while
   -- kb_key_pressed_n_i is signalling (low active) which key is pressed
   constant C_M65_INS_DEL     : integer          := 0;
   constant C_M65_RETURN      : integer          := 1;
   constant C_M65_HORZ_CRSR   : integer          := 2;  -- means cursor right in C64 terminology
   constant C_M65_F7          : integer          := 3;
   constant C_M65_F1          : integer          := 4;
   constant C_M65_F3          : integer          := 5;
   constant C_M65_F5          : integer          := 6;
   constant C_M65_VERT_CRSR   : integer          := 7;  -- means cursor down in C64 terminology
   constant C_M65_3           : integer          := 8;
   constant C_M65_W           : integer          := 9;
   constant C_M65_A           : integer          := 10;
   constant C_M65_4           : integer          := 11;
   constant C_M65_Z           : integer          := 12;
   constant C_M65_S           : integer          := 13;
   constant C_M65_E           : integer          := 14;
   constant C_M65_LEFT_SHIFT  : integer          := 15;
   constant C_M65_5           : integer          := 16;
   constant C_M65_R           : integer          := 17;
   constant C_M65_D           : integer          := 18;
   constant C_M65_6           : integer          := 19;
   constant C_M65_C           : integer          := 20;
   constant C_M65_F           : integer          := 21;
   constant C_M65_T           : integer          := 22;
   constant C_M65_X           : integer          := 23;
   constant C_M65_7           : integer          := 24;
   constant C_M65_Y           : integer          := 25;
   constant C_M65_G           : integer          := 26;
   constant C_M65_8           : integer          := 27;
   constant C_M65_B           : integer          := 28;
   constant C_M65_H           : integer          := 29;
   constant C_M65_U           : integer          := 30;
   constant C_M65_V           : integer          := 31;
   constant C_M65_9           : integer          := 32;
   constant C_M65_I           : integer          := 33;
   constant C_M65_J           : integer          := 34;
   constant C_M65_0           : integer          := 35;
   constant C_M65_M           : integer          := 36;
   constant C_M65_K           : integer          := 37;
   constant C_M65_O           : integer          := 38;
   constant C_M65_N           : integer          := 39;
   constant C_M65_PLUS        : integer          := 40;
   constant C_M65_P           : integer          := 41;
   constant C_M65_L           : integer          := 42;
   constant C_M65_MINUS       : integer          := 43;
   constant C_M65_DOT         : integer          := 44;
   constant C_M65_COLON       : integer          := 45;
   constant C_M65_AT          : integer          := 46;
   constant C_M65_COMMA       : integer          := 47;
   constant C_M65_GBP         : integer          := 48;
   constant C_M65_ASTERISK    : integer          := 49;
   constant C_M65_SEMICOLON   : integer          := 50;
   constant C_M65_CLR_HOME    : integer          := 51;
   constant C_M65_RIGHT_SHIFT : integer          := 52;
   constant C_M65_EQUAL       : integer          := 53;
   constant C_M65_ARROW_UP    : integer          := 54; -- symbol, not cursor
   constant C_M65_SLASH       : integer          := 55;
   constant C_M65_1           : integer          := 56;
   constant C_M65_ARROW_LEFT  : integer          := 57; -- symbol, not cursor
   constant C_M65_CTRL        : integer          := 58;
   constant C_M65_2           : integer          := 59;
   constant C_M65_SPACE       : integer          := 60;
   constant C_M65_MEGA        : integer          := 61;
   constant C_M65_Q           : integer          := 62;
   constant C_M65_RUN_STOP    : integer          := 63;
   constant C_M65_NO_SCRL     : integer          := 64;
   constant C_M65_TAB         : integer          := 65;
   constant C_M65_ALT         : integer          := 66;
   constant C_M65_HELP        : integer          := 67;
   constant C_M65_F9          : integer          := 68;
   constant C_M65_F11         : integer          := 69;
   constant C_M65_F13         : integer          := 70;
   constant C_M65_ESC         : integer          := 71;
   constant C_M65_CAPSLOCK    : integer          := 72;
   constant C_M65_UP_CRSR     : integer          := 73; -- cursor up
   constant C_M65_LEFT_CRSR   : integer          := 74; -- cursor left
   constant C_M65_RESTORE     : integer          := 75;
   constant C_M65_NONE        : integer          := 79;

   type     main_key_state_type is (UP_ST, DOWN_ST);
   signal   main_key_state  : main_key_state_type := UP_ST;
   signal   main_key_timer  : integer range 0 to G_MAIN_CLK_HZ;
   signal   main_kb_key_num : integer range 0 to 79;

   pure function key_lookup (
      arg : integer
   ) return std_logic_vector is
   begin
      --
      case arg is

         when C_M65_A =>
            return to_stdlogicvector(character'pos('A'), 8);

         when C_M65_B =>
            return to_stdlogicvector(character'pos('B'), 8);

         when C_M65_C =>
            return to_stdlogicvector(character'pos('C'), 8);

         when C_M65_D | C_M65_VERT_CRSR =>
            return to_stdlogicvector(character'pos('D'), 8);

         when C_M65_E =>
            return to_stdlogicvector(character'pos('E'), 8);

         when C_M65_F =>
            return to_stdlogicvector(character'pos('F'), 8);

         when C_M65_G =>
            return to_stdlogicvector(character'pos('G'), 8);

         when C_M65_H =>
            return to_stdlogicvector(character'pos('H'), 8);

         when C_M65_I =>
            return to_stdlogicvector(character'pos('I'), 8);

         when C_M65_J =>
            return to_stdlogicvector(character'pos('J'), 8);

         when C_M65_K =>
            return to_stdlogicvector(character'pos('K'), 8);

         when C_M65_L | C_M65_LEFT_CRSR =>
            return to_stdlogicvector(character'pos('L'), 8);

         when C_M65_M =>
            return to_stdlogicvector(character'pos('M'), 8);

         when C_M65_N =>
            return to_stdlogicvector(character'pos('N'), 8);

         when C_M65_O =>
            return to_stdlogicvector(character'pos('O'), 8);

         when C_M65_P =>
            return to_stdlogicvector(character'pos('P'), 8);

         when C_M65_Q =>
            return to_stdlogicvector(character'pos('Q'), 8);

         when C_M65_R | C_M65_HORZ_CRSR =>
            return to_stdlogicvector(character'pos('R'), 8);

         when C_M65_S =>
            return to_stdlogicvector(character'pos('S'), 8);

         when C_M65_T =>
            return to_stdlogicvector(character'pos('T'), 8);

         when C_M65_U | C_M65_UP_CRSR =>
            return to_stdlogicvector(character'pos('U'), 8);

         when C_M65_V =>
            return to_stdlogicvector(character'pos('V'), 8);

         when C_M65_W =>
            return to_stdlogicvector(character'pos('W'), 8);

         when C_M65_X =>
            return to_stdlogicvector(character'pos('X'), 8);

         when C_M65_Y =>
            return to_stdlogicvector(character'pos('Y'), 8);

         when C_M65_Z =>
            return to_stdlogicvector(character'pos('Z'), 8);

         when C_M65_SPACE =>
            return to_stdlogicvector(character'pos(' '), 8);

         when others =>
            return X"00";

      end case;

      return X"00";
   end function key_lookup;

begin

   main_key_data_o  <= key_lookup(main_kb_key_num);

   key_proc : process (main_clk_i)
   begin
      if rising_edge(main_clk_i) then
         main_key_valid_o <= '0';

         case main_key_state is

            when UP_ST =>
               -- A key is pressed
               if main_kb_key_pressed_n_i = '0' then
                  main_kb_key_num  <= main_kb_key_num_i;
                  main_key_valid_o <= '1';
                  main_key_timer   <= G_MAIN_CLK_HZ / 2;
                  main_key_state   <= DOWN_ST;
               end if;

            when DOWN_ST =>
               -- A different key is pressed
               if main_kb_key_pressed_n_i = '0' and main_kb_key_num /= main_kb_key_num_i then
                  main_kb_key_num  <= main_kb_key_num_i;
                  main_key_valid_o <= '1';
                  main_key_timer   <= G_MAIN_CLK_HZ / 2;
               end if;

               -- The key is released
               if main_kb_key_pressed_n_i = '1' and main_kb_key_num = main_kb_key_num_i then
                  main_key_state <= UP_ST;
               else
                  -- The key is still pressed
                  if main_key_timer > 0 then
                     main_key_timer <= main_key_timer - 1;
                  else
                     main_key_valid_o <= '1';
                     main_key_timer   <= G_MAIN_CLK_HZ / 10;
                  end if;
               end if;

         end case;

         if main_rst_i = '1' then
            main_key_state   <= UP_ST;
            main_key_timer   <= G_MAIN_CLK_HZ / 2;
            main_kb_key_num  <= 0;
            main_key_valid_o <= '0';
         end if;
      end if;
   end process key_proc;

end architecture synthesis;

