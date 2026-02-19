library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EdgeDetector is
    generic(edge: std_ulogic := '1');
    port(
        clk, data_in: in std_ulogic;
        data_out: out std_ulogic
    );
end;

architecture behaviour of EdgeDetector is
    signal prev: std_ulogic := '0';
begin
    reg: entity work.Reg generic map (1) port map (clk, '1', data_in(0) => data_in, data_out(0) => prev);
    data_out <= '1' when prev /= data_in and data_in = edge else '0';
end;
