library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Reg is
    generic(size: positive; clk_edge: std_ulogic := '1');
    port(
        clk, w: in std_ulogic;
        data_in: in std_ulogic_vector(size - 1 downto 0);
        data_out: out std_ulogic_vector(size - 1 downto 0) := (others => '0')
    );
end;

architecture behaviour of Reg is
begin
    process(clk)
    begin
        if clk'event and clk = clk_edge then
            if w then
                data_out <= data_in;
            end if;
        end if;
    end process;
end;
