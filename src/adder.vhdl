library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Adder is
    generic(size: positive);
    port(
        a, b: in signed(size - 1 downto 0);
        c: buffer signed(size - 1 downto 0);
        subtraction: in std_ulogic;
        overflow: out std_ulogic
    );
end;

architecture behaviour of Adder is
    signal a_extended, b_extended, c_extended: signed(size downto 0);
begin
    a_extended <= resize(a, size + 1);
    b_extended <= resize(b, size + 1);
    c_extended <= a_extended + b_extended when not subtraction else a_extended - b_extended;

    c <= c_extended(size - 1 downto 0);
    overflow <= '1' when c_extended(size) /= c_extended(size - 1) else '0';
end;
