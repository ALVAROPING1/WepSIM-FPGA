context work.tb_context;

use ieee.math_real.all;
use work.utils;
use src.utils.std_ulogic_matrix;

entity UARTTX_TB is
    generic (
        runner_cfg: string;
    );
end;

architecture behaviour of UARTTX_TB is
    constant CLK_MUL: positive := 16;
    constant UART_PERIOD: time := 2 us * CLK_MUL;
    signal clk, clk_uart, iow, accept_in, accepted: std_ulogic := '0';
    signal tx, tx_filtered, cts: std_ulogic := '1';
    signal send_data: std_ulogic_vector(7 downto 0);
    signal data: std_ulogic_matrix(1 to 2000)(7 downto 0);
    signal tx_state: unsigned(1 downto 0) := "00";
begin
    dut: entity src.UARTTX port map (clk, '1', iow, tx, cts, send_data, accept_in, accepted);

    utils.clk_gen(clk);
    utils.clk_gen(clk_uart, period => UART_PERIOD);

    filter: process
    begin
        wait for UART_PERIOD / 8;
        tx_state <= tx_state - 1 when tx = '0' and tx_state /= "00" else
                    tx_state + 1 when tx = '1' and tx_state /= "11" else
                    tx_state;
    end process;
    tx_filtered <= tx_state(tx_state'high);

    pc: process
        variable rnd: RandomPType;
    begin
        cts <= '0';
        for l in data'range loop
            wait for rnd.RandTime(0 us, 1 * UART_PERIOD);
            while tx_filtered loop wait for UART_PERIOD; end loop;
            check_equal(tx_filtered, '0', "Check transmission bit (start bit)");
            check_equal(accept_in, '0', "Check more data can't be sent (start bit)");
            info("Detected start bit");
            wait for UART_PERIOD;
            for i in 0 to 7 loop
                check_equal(tx_filtered, data(l)(i), "Check transmission bit " & to_string(i));
                check_equal(accept_in, '0', "Check more data can't be sent (transmission bit " & to_string(i) & ")");
                wait for UART_PERIOD;
            end loop;
            check_equal(tx_filtered, '1', "Check transmission bit (stop bit)");
        end loop;
    end process;

    fpga: process
        variable rnd: RandomPType;
        variable curr: std_ulogic_vector(7 downto 0);
    begin
        test_runner_setup(runner, runner_cfg);
        wait for 1 us;
        for l in data'range loop
            while not accept_in loop wait for 2 us; end loop;
            curr := rnd.RandSlv(8);
            data(l) <= curr;
            info("Receiving " & to_string(curr) & ", check sent data");
            iow <= '1';
            send_data <= curr;
            check_equal(accepted, '0', "Check accepted");
            check_equal(accept_in, '1', "Check accepted");
            while accept_in loop wait for 2 us; end loop;
            check_equal(accepted, '0', "Check accepted");
            check_equal(accept_in, '0', "Check accepted");
            while not accepted loop wait for 2 us; end loop;
            check_equal(accepted, '1', "Check accepted");
            check_equal(accept_in, '0', "Check accepted");
            if rnd.RandInt(0, 9) = 0 then
                iow <= '0';
                send_data <= (others => 'Z');
                wait for 2 us * rnd.RandInt(2, 5) * CLK_MUL;
                check_equal(accepted, '0', "Check accepted");
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
