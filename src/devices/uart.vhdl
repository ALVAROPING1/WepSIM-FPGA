library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity UART is
    generic(size, clk_freq, baud_rate: positive);
    port(
        -- CPU
        clk, iow, ior: in std_ulogic;
        addr: in unsigned(15 downto 0);
        data: inout std_logic_vector(size - 1 downto 0);
        -- UART pins
        rx, cts: in std_ulogic;
        tx, rts: out std_ulogic;
    );
end;

architecture behaviour of UART is
    constant WRITE_ADDR:        addr'subtype := x"1000";
    constant WRITE_STATUS_ADDR: addr'subtype := x"1004";
    constant READ_ADDR:         addr'subtype := x"0100";
    constant READ_STATUS_ADDR:  addr'subtype := x"0104";
    signal receive_data: std_ulogic_vector(7 downto 0);
    signal rd, wd, rs, ws, can_send, can_receive: std_ulogic := '0';
    constant PAD8: std_ulogic_vector(size - 1 downto 8) := (others => '0');
    constant PAD1: std_ulogic_vector(size - 1 downto 1) := (others => '0');
begin
    rd <= '1' when ior = '1' and addr = READ_ADDR else '0';
    wd <= '1' when iow = '1' and addr = WRITE_ADDR else '0';
    rs <= '1' when ior = '1' and addr = READ_STATUS_ADDR else '0';
    ws <= '1' when ior = '1' and addr = WRITE_STATUS_ADDR else '0';

    controller: entity work.UARTController
        generic map (clk_freq, baud_rate)
        port map (clk, wd, rd, rx, cts, tx, rts, data(7 downto 0), receive_data, can_send, can_receive);

    read_data: entity work.TriState generic map (size) port map (PAD8 & receive_data, data, rd);
    read_status: entity work.TriState generic map (size) port map (PAD1 & can_receive, data, rs);
    write_status: entity work.TriState generic map (size) port map (PAD1 & can_send, data, ws);
end;
