library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package utils is
    type std_ulogic_matrix is array(natural range <>) of std_ulogic_vector;
    type unsigned_vector is array(natural range <>) of unsigned;
end package;
