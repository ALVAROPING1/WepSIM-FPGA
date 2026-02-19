context work.tb_context;

use ieee.math_real.all;
use work.utils;
use src.utils.std_ulogic_matrix;

entity UARTController_TB is
    generic (
        runner_cfg: string;
    );
end;

architecture behaviour of UARTController_TB is
    constant BUF_SIZE: positive := 16;
    constant CLK_MUL: positive := 16;
    constant UART_PERIOD: time := 2 us * CLK_MUL;
    signal clk, clk_uart, ior, iow: std_ulogic := '0';
    signal rx, cts, tx, rts: std_ulogic := '1';
    signal send_data, receive_data, pc_send, pc_receive: std_ulogic_vector(7 downto 0);
    signal can_send, can_receive, rx_valid, accept_in, accepted: std_ulogic := '0';
    signal count: integer_vector(1 to 2000) := (others => -1);
    signal data: src.utils.std_ulogic_matrix(count'range)(7 downto 0);
    signal done: boolean := false;
begin
    dut: entity src.UARTController
        generic map (CLK_MUL, 1, BUF_SIZE)
        port map (clk, ior, iow, rx, cts, tx, rts, send_data, receive_data, can_send, can_receive);

    uart_tx: entity src.UARTTX port map (clk, '1', '1', rx, rts, pc_send, accept_in => accept_in, accepted => accepted);
    uart_rx: entity src.UARTRX port map (clk, '1', '1', tx, cts, pc_receive, rx_valid);

    utils.clk_gen(clk);
    utils.clk_gen(clk_uart, period => UART_PERIOD);

    pc_tx: process
        variable rnd: RandomPType;
        variable curr: send_data'subtype;
    begin
        wait for 1 us;
        for l in data'range loop
            while not accept_in loop wait for 2 us; end loop;
            curr := rnd.RandSlv(8);
            data(l) <= curr;
            pc_send <= curr;
            while not accepted loop wait for 2 us; end loop;
        end loop;
        wait;
    end process;

    pc_rx: process
    begin
        test_runner_setup(runner, runner_cfg);
        for l in data'range loop
            while count(l) < 0 loop wait for 2 us; end loop;
            for r in 1 to count(l) loop
                info("pc rx: " & to_string(l) & " - " & to_string(r));
                while not rx_valid loop wait for UART_PERIOD; end loop;
                check_equal(pc_receive, data(l), "Check received data");
                wait for UART_PERIOD;
            end loop;
        end loop;
        done <= true;
        test_runner_cleanup(runner);
    end process;

    fpga: process
        variable rnd: RandomPType;
        variable repeats: positive;
    begin
        wait for 1 us;
        for l in data'range loop
            if rnd.RandInt(0, 9) = 0 then
                wait for UART_PERIOD * 10 * BUF_SIZE * rnd.RandInt(1, 8) / 4;
            end if;
            while not (can_send and can_receive) loop wait for 2 us; end loop;
            ior <= '1', '0' after 2 us;
            send_data <= receive_data;
            repeats := rnd.RandInt(2, 8) when rnd.RandInt(0, 9) = 0 else 1;
            count(l) <= repeats;
            for r in 1 to repeats loop
                info("fpga tx: " & to_string(l) & " - " & to_string(r));
                iow <= '1';
                wait for 2 us;
                iow <= '0';
                while not can_send loop wait for 2 us; end loop;
            end loop;
        end loop;
    end process;
end;
