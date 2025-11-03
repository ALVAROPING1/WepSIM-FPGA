library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.std_ulogic_matrix;

entity Demultiplexer is
    generic(size, addr_size: positive);
    port(
        data_in: in std_ulogic_vector(size - 1 downto 0);
        data_out: out std_ulogic_matrix(0 to 2**addr_size - 1)(size - 1 downto 0);
        sel: in unsigned(addr_size - 1 downto 0)
    );
end;

architecture behaviour of Demultiplexer is
begin
    process(all)
    begin
        data_out <= (others => (others => 'Z'));
        data_out(to_integer(sel)) <= data_in;
    end process;
end;
