library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.std_ulogic_matrix;
use work.utils.natural_vector;

entity RegisterFile is
    generic(size, addresses, read_outputs: positive);
    port(
        clk, rst, w: in std_ulogic;
        w_addr: in natural range 0 to addresses - 1;
        w_data: in std_ulogic_vector(size - 1 downto 0);
        r_addr: in natural_vector(0 to read_outputs - 1);
        r_data: out std_ulogic_matrix(0 to read_outputs - 1)(size - 1 downto 0)
    );
end;

architecture behaviour of RegisterFile is
    type State is array (natural range 0 to addresses - 1) of std_ulogic_vector(w_data'range);
    signal contents: State;
begin
    write: process(clk, rst)
    begin
        if rst then
            contents <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if w then
                contents(w_addr) <= w_data;
            end if;
        end if;
    end process;

    read: process(all)
    begin
        for i in r_addr'range loop
            assert r_addr(i) < addresses
                report "Invalid read address: " & to_string(r_addr(i))
                severity failure;
            r_data(i) <= contents(r_addr(i));
        end loop;
    end process;
end;
