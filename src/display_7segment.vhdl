library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.bcd.bcd_vector;
use work.bcd.digit;

entity Display7segment is
    generic(size: positive);
    port(
        clk, rst: in std_ulogic;
        data_in: in bcd_vector(size - 1 downto 0);
        segment: out std_ulogic_vector(7 downto 0);
        enable: out natural range 0 to size - 1
    );
end;

architecture behaviour of Display7segment is
    signal idx: natural range 0 to size - 1 := 0;
    type digit_table is array (natural range 0 to 9) of std_ulogic_vector(7 downto 0);
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
        "01101111"
    );
begin
    process(clk, rst)
    begin
        if rst then
            idx <= 0;
        elsif rising_edge(clk) then
            idx <= (idx + 1) mod size;
        end if;
    end process;

    enable <= idx;
    segment <= tbl(data_in(idx));
end;
