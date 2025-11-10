library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Source is
    generic(x: std_ulogic_vector);
    port(value: out std_ulogic_vector);
end;

architecture behaviour of Source is
begin
    value <= x;
end;
