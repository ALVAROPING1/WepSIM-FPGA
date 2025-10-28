library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TriState is
    generic(size: positive);
    port(
        data_in: in std_ulogic_vector(size - 1 downto 0);
        data_out: out std_ulogic_vector(size - 1 downto 0);
        enable: in boolean
    );
end;

architecture behaviour of TriState is
begin
    data_out <= data_in when enable else (others => 'Z');
end;
