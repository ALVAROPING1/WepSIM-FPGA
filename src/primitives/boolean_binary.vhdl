library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BooleanBinary is
    generic(
        size: positive;
        pure function mapper(a, b: std_ulogic_vector) return std_ulogic_vector
    );
    port(
        a, b: in std_ulogic_vector(size - 1 downto 0);
        c: out std_ulogic_vector(size - 1 downto 0)
    );
end;

architecture behaviour of BooleanBinary is
begin
    c <= mapper(a, b);
end;
