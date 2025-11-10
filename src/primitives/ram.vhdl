library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    generic(size, addr_size: positive);
    port(
        clk, rst, w, r: in std_ulogic;
        addr: in unsigned(addr_size - 1 downto 0);
        data: inout std_ulogic_vector(size - 1 downto 0)
    );
end;

architecture behaviour of RAM is
    type State is array (natural range 0 to 2**addr_size - 1) of std_ulogic_vector(data'range);
    signal contents: State;
    signal raddr: natural range State'range;
begin
    process(clk, rst)
    begin
        if rst then
            contents <= (others => (others => '0'));
        elsif rising_edge(clk) then
            raddr <= to_integer(addr);
            if w then
                contents(to_integer(addr)) <= data;
            end if;
        end if;
    end process;
    data <= contents(raddr) when not w and r else (others => 'Z');

end;
