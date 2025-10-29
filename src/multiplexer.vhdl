library ieee;
use ieee.std_logic_1164.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.std_ulogic_matrix;

entity Multiplexer is
    generic(size, addresses: positive);
    port(
        data_in: in std_ulogic_matrix(0 to addresses - 1)(size - 1 downto 0);
        data_out: out std_ulogic_vector(size - 1 downto 0);
        sel: in natural range 0 to addresses - 1
    );
end;

architecture behaviour of Multiplexer is
begin
    data_out <= data_in(sel);
end;
