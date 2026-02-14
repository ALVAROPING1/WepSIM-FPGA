library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.utils;

entity ClkDivider is
    generic(in_freq, out_freq: positive);
    port(
        clk_in: in std_ulogic;
        clk_out: out std_ulogic := '0'
    );
end;

architecture behaviour of ClkDivider is
    constant GCD: positive := utils.gcd(in_freq, out_freq);
    constant DENOMINATOR: positive := in_freq / GCD;
    constant NUMERATOR: positive := out_freq / GCD;
    constant BITS: positive := utils.bits(DENOMINATOR);

    signal counter: signed(BITS downto 0) := to_signed(-1, BITS + 1);
begin
    clk_divider: process(clk_in)
    begin
        if rising_edge(clk_in) then
            if counter < 0 then
                clk_out <= '1';
                counter <= counter + DENOMINATOR - NUMERATOR;
            else
                clk_out <= '0';
                counter <= counter - NUMERATOR;
            end if;
        end if;
    end process;
end;
