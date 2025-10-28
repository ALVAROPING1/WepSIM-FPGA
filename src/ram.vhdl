library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    generic(size, addresses: positive);
    port(
        clk, rst, w, r: std_ulogic;
        addr: natural range 0 to addresses - 1;
        data: inout std_ulogic_vector(size - 1 downto 0)
    );
end;

architecture behaviour of RAM is
    type State is array (natural range 0 to addresses - 1) of std_ulogic_vector(data'range);
    signal contents: State;
    signal raddr: natural range 0 to addresses - 1;
begin
    process(clk, rst)
    begin
        if rst then
            contents <= (others => (others => '0'));
        elsif rising_edge(clk) then
            raddr <= addr;
            if w then
                contents(addr) <= data;
            end if;
        end if;
    end process;
    data <= contents(raddr) when not w and r else (others => 'Z');

end;
