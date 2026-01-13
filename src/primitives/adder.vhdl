library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Adder is
    generic(size: positive);
    port(
        a, b: in signed(size - 1 downto 0);
        c: out signed(size - 1 downto 0);
        subtraction: in std_ulogic;
        signed_arith: in std_ulogic;
        overflow, carry: out std_ulogic
    );
end;

architecture behaviour of Adder is
    signal a_extended, b_extended, c_extended: signed(size downto 0);
begin
    a_extended(a'range) <= a;
    b_extended(b'range) <= b;
    a_extended(size) <= a(a'high) when signed_arith else '0';
    b_extended(size) <= b(b'high) when signed_arith else '0';
    c_extended <= a_extended + b_extended when not subtraction else a_extended - b_extended;

    c <= c_extended(c'range);
    -- Carry should be ignored on signed arithmetic, and overflow should be
    -- ignored on unsigned arithmetic
    carry <= c_extended(size);
    overflow <= '1' when c_extended(size) /= c_extended(size - 1) else '0';
end;
