library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.std_ulogic_matrix;
use work.utils.unsigned_vector;

entity RegisterFile is
    generic(size, addr_size, read_outputs: positive; clk_edge: std_ulogic := '1');
    port(
        clk, rst, w: in std_ulogic;
        w_addr: in unsigned(addr_size - 1 downto 0);
        w_data: in std_ulogic_vector(size - 1 downto 0);
        r_addr: in unsigned_vector(0 to read_outputs - 1)(addr_size - 1 downto 0);
        r_data: out std_ulogic_matrix(0 to read_outputs - 1)(size - 1 downto 0)
    );
end;

architecture behaviour of RegisterFile is
    type State is array (natural range 0 to 2**addr_size - 1) of std_ulogic_vector(w_data'range);
    signal contents: State;
begin
    write: process(clk, rst)
    begin
        if rst then
            contents <= (others => (others => '0'));
        elsif clk'event and clk = clk_edge then
            if w then
                contents(to_integer(w_addr)) <= w_data;
            end if;
        end if;
    end process;

    read: process(all)
    begin
        for i in r_addr'range loop
            r_data(i) <= contents(to_integer(r_addr(i)));
        end loop;
    end process;
end;
