library ieee;
use ieee.std_logic_1164.all;

package utils is
    type std_ulogic_matrix is array(natural range <>) of std_ulogic_vector;
    type natural_vector is array(natural range <>) of natural;
end package;
