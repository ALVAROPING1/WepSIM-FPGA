library ieee;
use ieee.std_logic_1164.all;

package multiplexer_pkg is
    type data is array(natural range <>) of std_ulogic_vector;
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.multiplexer_pkg;

entity Multiplexer is
    generic(size, addresses: positive);
    port(
        data_in: in multiplexer_pkg.data(0 to addresses - 1)(size - 1 downto 0);
        data_out: out std_ulogic_vector(size - 1 downto 0);
        sel: natural range 0 to addresses - 1
    );
end;

architecture behaviour of Multiplexer is
begin
    data_out <= data_in(sel);
end;
