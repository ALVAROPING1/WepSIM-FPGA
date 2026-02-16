context work.tb_context;

use ieee.math_real.all;
use work.utils;
use src.utils.std_ulogic_matrix;

entity UARTRX_TB is
    generic (
        runner_cfg: string;
        clk_freq, baud_rate: positive
    );
end;

architecture behaviour of UARTRX_TB is
    constant UART_PERIOD: time := 2 us * real(clk_freq) / real(baud_rate);
    signal clk, clk_e, clk_uart, ior, data_valid: std_ulogic := '0';
    signal rx, rts: std_ulogic := '1';
    signal receive_data: std_ulogic_vector(7 downto 0);
    signal data: std_ulogic_matrix(1 to 2000)(7 downto 0);
begin
    clk_div: entity src.ClkDivider
        generic map (clk_freq, baud_rate*16)
        port map (clk, clk_e);

    dut: entity src.UARTRX port map (clk, clk_e, ior, rx, rts, receive_data, data_valid);

    utils.clk_gen(clk);
    utils.clk_gen(clk_uart, period => UART_PERIOD);

    pc: process
        variable rnd: RandomPType;
        variable curr: std_ulogic_vector(7 downto 0);
    begin
        for l in data'range loop
            wait for rnd.RandTime(0 us, 2 * UART_PERIOD);
            while rts loop wait for UART_PERIOD; end loop;
            curr := rnd.RandSlv(8);
            data(l) <= curr;
            info("Sending " & to_string(curr) & ", check received data");
            check_equal(rts, '0', "Check data can be sent over UART (start bit)");
            check_equal(data_valid, '0', "Check received data isn't yet valid (start bit)");
            rx <= '0';
            wait for UART_PERIOD;
            for i in 0 to 7 loop
                check_equal(rts, '0', "Check data can be sent over UART (transmission bit " & to_string(i) & ")");
                check_equal(data_valid, '0', "Check received data isn't yet valid ((transmission bit " & to_string(i) & ")");
                rx <= curr(i);
                wait for UART_PERIOD;
            end loop;
            check_equal(data_valid, '1', "Check received data is valid (end bit)");
            rx <= '1';
            wait for UART_PERIOD;
        end loop;
    end process;

    fpga: process
        variable rnd: RandomPType;
    begin
        test_runner_setup(runner, runner_cfg);
        wait for 1 us;
        for l in data'range loop
            ior <= '1';
            while not data_valid loop wait for 2 us; end loop;
            for i in 1 to 10 loop
                check_equal(rts, '0', "Check data can be sent over UART");
                check_equal(data_valid, '1', "Check received data is valid");
                check_equal(receive_data, data(l), "Check received data");
                wait for 2 us;
            end loop;
            if rnd.RandInt(0, 9) = 0 then
                ior <= '0';
                check_equal(rts, '0', "Check data can be sent over UART");
                check_equal(data_valid, '1', "Check received data is valid");
                check_equal(receive_data, data(l), "Check received data");
                wait for 2 us;
                check_equal(rts, '1', "Check data can't be sent over UART");
                wait for 2 us * rnd.RandInt(1, 5) * clk_freq / baud_rate;
            end if;
            while data_valid loop wait for 2 us; end loop;
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
