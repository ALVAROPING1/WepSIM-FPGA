library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.std_ulogic_matrix;

entity Demultiplexer is
    generic(size, addresses: positive);
    port(
        data_in: in std_ulogic_vector(size - 1 downto 0);
        data_out: out std_ulogic_matrix(0 to addresses - 1)(size - 1 downto 0);
        sel: in natural range 0 to addresses - 1
    );
end;

architecture behaviour of Demultiplexer is
begin
    process(all)
    begin
        data_out <= (others => (others => 'Z'));
        data_out(sel) <= data_in;
    end process;
end;
