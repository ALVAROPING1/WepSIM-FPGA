library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package utils is
    type std_ulogic_matrix is array(natural range <>) of std_ulogic_vector;
    type unsigned_vector is array(natural range <>) of unsigned;

    pure function maybe_signed(x: std_ulogic_vector; as_signed: std_ulogic) return signed;

    pure function lcm(a, b: natural) return natural;
    pure function gcd(a, b: natural) return natural;
    pure function bits(x: natural) return natural;
    pure function inc_mod(x: natural; m: positive) return natural;
end package;

package body utils is
    pure function maybe_signed(x: std_ulogic_vector; as_signed: std_ulogic) return signed is
    begin
        return (x(x'high) and as_signed) & signed(x);
    end function;

    pure function lcm(a, b: natural) return natural is
    begin
        return a * b / gcd(a, b);
    end function;

    pure function gcd(a, b: natural) return natural is
        variable max: integer := maximum(a, b);
        variable min: integer := minimum(a, b);
        variable res: integer;
    begin
        loop
            res := max mod min;
            if res = 0 then
                return min;
            end if;

            max := min;
            min := res;
        end loop;
    end function;

    pure function bits(x: natural) return natural is
        use ieee.math_real.all;
    begin
        return natural(floor(log2(real(x)))) + 1;
    end function;

    pure function inc_mod(x: natural; m: positive) return natural is
    begin
        if x < m - 1 then
            return x + 1;
        else
            return 0;
        end if;
    end function;
end package body utils;
