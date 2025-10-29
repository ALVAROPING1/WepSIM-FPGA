library ieee;
use ieee.std_logic_1164.all;

package utils is
    procedure clk_gen(
        signal clk: out std_ulogic;
        constant period: time := 2 us
    );
end package;

package body utils is
    procedure clk_gen(
        signal clk: out std_ulogic;
        constant period: time := 2 us
    ) is
    begin
        loop
            clk <= '1', '0' after period/2;
            wait for period;
        end loop;
    end;
end package body;
