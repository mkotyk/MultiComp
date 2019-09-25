library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity hex_decoder is
    port (
        nibble: in unsigned(3 downto 0);
        output: out std_logic_vector(6 downto 0)
    );
end hex_decoder;

architecture Behavioral of hex_decoder is
begin
    process(nibble)
    begin
        case nibble is
            when X"0" => output <= b"1000000"; -- // ---t----
            when X"1" => output <= b"1111001"; -- // |      |
            when X"2" => output <= b"0100100"; -- // lt    rt
            when X"3" => output <= b"0110000"; -- // |      |
            when X"4" => output <= b"0011001"; -- // ---m----
            when X"5" => output <= b"0010010"; -- // |      |
            when X"6" => output <= b"0000010"; -- // lb    rb
            when X"7" => output <= b"1111000"; -- // |      |
            when X"8" => output <= b"0000000"; -- // ---b----
            when X"9" => output <= b"0011000";
            when X"A" => output <= b"0001000";
            when X"B" => output <= b"0000011";
            when X"C" => output <= b"1000110";
            when X"D" => output <= b"0100001";
            when X"E" => output <= b"0000110";
            when X"F" => output <= b"0001110";
        end case;
    end process;
end Behavioral;
