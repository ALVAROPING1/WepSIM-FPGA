library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Multiplier is
    generic(size: positive);
    port(
        a, b: in std_ulogic_vector(size - 1 downto 0);
        signed_a, signed_b: in std_ulogic;
        c: out signed(size * 2 - 1 downto 0);
        overflow: out std_ulogic
    );
end;

architecture behaviour of Multiplier is
    signal sign_bit: signed(size downto 0);
    signal res: signed(c'high + 2 downto 0);
    signal c_buf: c'subtype;
    use work.utils.maybe_signed;
begin
    res <= maybe_signed(a, signed_a) * maybe_signed(b, signed_b);
    c_buf <= res(c'range);
    c <= c_buf;

    sign_bit <= (others => c_buf(c'high));
    overflow <= '1' when c_buf(size * 2 - 1 downto size - 1) /= sign_bit else '0';
end;
