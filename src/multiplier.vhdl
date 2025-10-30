library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Multiplier is
    generic(size: positive);
    port(
        a, b: in signed(size - 1 downto 0);
        c: buffer signed(size * 2 - 1 downto 0);
        overflow: out std_ulogic
    );
end;

architecture behaviour of Multiplier is
    signal sign_bit: signed(size downto 0);
begin
    c <= a * b;

    sign_bit <= (others => c(c'high));
    overflow <= '1' when c(size * 2 - 1 downto size - 1) /= sign_bit else '0';
end;
