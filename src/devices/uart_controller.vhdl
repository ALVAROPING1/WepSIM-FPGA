library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity UARTController is
    generic(
        clk_freq, baud_rate: positive;
        buf_size: positive := 256;
        almost_full_level: natural range 0 to buf_size := buf_size / 2;
    );
    port(
        -- CPU control signals
        clk, ior, iow: in std_ulogic;
        -- UART pins
        rx, cts: in std_ulogic;
        tx, rts: out std_ulogic;
        -- CPU input/output
        send_data: in std_ulogic_vector(7 downto 0);
        receive_data: out std_ulogic_vector(7 downto 0);
        -- CPU status signals
        can_send, can_receive: out std_ulogic
    );
end;

architecture behaviour of UARTController is
    signal clk_e: std_ulogic := '0';
    signal tx_full, tx_empty, tx_accepted, tx_read: std_ulogic;
    signal rx_af, rx_empty, rx_valid, rx_write: std_ulogic;
    signal rx_data, tx_data: std_ulogic_vector(7 downto 0);
begin
    clk_div: entity work.ClkDivider
        generic map (clk_freq, baud_rate*8)
        port map (clk, clk_e);

    uart_tx: entity work.UARTTX port map (clk, clk_e, not tx_empty, tx, cts, tx_data, tx_accepted);
    uart_rx: entity work.UARTRX port map (clk, clk_e, not rx_af, rx, rts, rx_data, rx_valid);

    accepted_edge: entity work.EdgeDetector port map (clk, tx_accepted, tx_read);
    valid_edge: entity work.EdgeDetector port map (clk, rx_valid, rx_write);

    fifo_tx: entity work.FIFO
        generic map (8, buf_size)
        port map (
            clk, tx_read, iow,
            send_data,
            tx_data,
            full => tx_full, empty => tx_empty,
            almost_full => open, almost_empty => open
        );
    fifo_rx: entity work.FIFO
        generic map (8, buf_size, almost_full_level)
        port map (
            clk, ior, rx_write,
            rx_data,
            receive_data,
            full => open, empty => rx_empty,
            almost_full => rx_af, almost_empty => open
        );
    can_send <= not tx_full;
    can_receive <= not rx_empty;
end;
