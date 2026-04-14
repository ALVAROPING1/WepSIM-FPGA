library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SegmentDisplayController is
    generic(digits: positive; clk_subsample_bits: positive := 14);
    port(
        clk, display_hex: in std_ulogic;
        data_in: in std_ulogic_vector(digits * 8 - 1 downto 0);
        segment: out std_ulogic_vector(7 downto 0);
        enable: out natural range 0 to digits - 1
    );
end;

architecture behaviour of SegmentDisplayController is
    signal acc: unsigned(clk_subsample_bits - 1 downto 0) := (others => '0');
    signal pos: natural range 0 to enable'high := 0;

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
        variable n_acc: unsigned(acc'range);
    begin
        if rising_edge(clk) then
            n_acc := acc + 1;
            if acc(acc'high) /= n_acc(acc'high) then
                enable <= (enable + 1) mod digits;
            end if;
            acc <= n_acc;
        end if;
    end process;

    enable <= pos;
    segment <= tbl(to_integer(unsigned(data_in(pos * 4 + 3 downto pos * 4)))) when display_hex else
               data_in(pos * 8 + 7 downto pos * 8);
end;
