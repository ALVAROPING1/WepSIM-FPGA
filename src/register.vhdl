library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Reg is
    generic(size: positive);
    port(
        clk, rst, w: std_ulogic;
        data_in: in std_ulogic_vector(size - 1 downto 0);
        data_out: out std_ulogic_vector(size - 1 downto 0)
    );
end;

architecture behaviour of Reg is
begin
    process(clk, rst)
    begin
        if rst then
            data_out <= (others => '0');
        elsif rising_edge(clk) then
            if w then
                data_out <= data_in;
            end if;
        end if;
    end process;
end;
