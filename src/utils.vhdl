library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package utils is
    type std_ulogic_matrix is array(natural range <>) of std_ulogic_vector;
    type unsigned_vector is array(natural range <>) of unsigned;

    pure function maybe_signed(x: std_ulogic_vector; as_signed: std_ulogic) return signed;
end package;

package body utils is
    pure function maybe_signed(x: std_ulogic_vector; as_signed: std_ulogic) return signed is
    begin
        return (x(x'high) and as_signed) & signed(x);
    end function;
end package body utils;
