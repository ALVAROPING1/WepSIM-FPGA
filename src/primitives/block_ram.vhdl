library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.std_ulogic_matrix;

entity BlockRAM is
    generic(
        byte_size, addr_size, n_bytes: positive;
        clk_edge: std_ulogic := '1';
        initial_content: std_ulogic_matrix(0 to 2**addr_size - 1)(n_bytes * byte_size - 1 downto 0)
            := (others => (others => '0'))
    );
    port(
        clk: in std_ulogic;
        w_enable: in std_ulogic_vector(n_bytes - 1 downto 0);
        addr: in unsigned(addr_size - 1 downto 0);
        data_in: in initial_content'element;
        data_out: out initial_content'element;
    );
end;

architecture behaviour of BlockRAM is
    signal RAM: initial_content'subtype := initial_content;
    attribute ram_style: string;
    attribute ram_style of RAM: signal is "block";

    signal word_addr: natural range RAM'range;
begin
    word_addr <= to_integer(addr);

    process(clk)
        variable low, high: natural range data_in'range;
    begin
        if clk'event and clk = clk_edge then
            data_out <= RAM(word_addr);
            for i in w_enable'range loop
                if w_enable(i) then
                    low  := i * byte_size;
                    high := low + byte_size - 1;
                    RAM(word_addr)(high downto low) <= data_in(high downto low);
                end if;
            end loop;
        end if;
    end process;
end;
