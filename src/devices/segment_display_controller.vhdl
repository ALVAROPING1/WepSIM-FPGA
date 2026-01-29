library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SegmentDisplayController is
    generic(digits: positive);
    port(
        clk, display_hex: in std_ulogic;
        data_in: in std_ulogic_vector(digits * 8 - 1 downto 0);
        segment: out std_ulogic_vector(7 downto 0);
        enable: buffer natural range 0 to digits - 1 := 0
    );
end;

architecture behaviour of SegmentDisplayController is
    type digit_table is array (natural range 0 to 15) of std_ulogic_vector(7 downto 0);
    constant tbl: digit_table := (
        "00111111",
        "00000110",
        "01011011",
        "01001111",
        "01100110",
        "01101101",
        "01111101",
        "00000111",
        "01111111",
        "01101111",
        "01110111",
        "01111100",
        "00111001",
        "01011110",
        "01111001",
        "01110001"
    );
begin
    process(clk)
    begin
        if rising_edge(clk) then
            enable <= (enable + 1) mod digits;
        end if;
    end process;

    segment <= tbl(to_integer(unsigned(data_in(enable * 4 + 3 downto enable * 4)))) when display_hex else
               data_in(enable * 8 + 7 downto enable * 8);
end;
