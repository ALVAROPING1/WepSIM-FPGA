library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Boolean is
    generic(
        size: positive;
        pure function reducer(data: std_ulogic_vector) return std_ulogic
    );
    port(
        data: in std_ulogic_vector(size - 1 downto 0);
        res: out std_ulogic
    );
end;

architecture behaviour of Boolean is
begin
    res <= reducer(data);
end;
