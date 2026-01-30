context work.tb_context;

use work.utils;

entity EdgeDetector_TB is
    generic (
        runner_cfg: string;
        edge: std_ulogic
    );
end;

architecture tb of EdgeDetector_TB is
    signal clk, data_in, data_out: std_ulogic := '0';
begin
    dut: entity src.EdgeDetector generic map (edge) port map(clk, data_in, data_out);

    utils.clk_gen(clk);

    main: process
        variable rnd: RandomPType;
    begin
        test_runner_setup(runner, runner_cfg);
        wait for 0.5 us;
        for i in 0 to 100 loop
            data_in <= '1';
            wait for 0.5 us;
            check_equal(data_out, edge, "Check rising edge");
            wait for 1.5 us;
            check_equal(data_out, '0', "Check after rising edge");
            for d in 0 to rnd.RandInt(50) loop
                wait for 2 us;
                check_equal(data_out, '0', "Check wait high");
            end loop;

            data_in <= '0';
            wait for 0.5 us;
            check_equal(data_out, not edge, "Check falling edge");
            wait for 1.5 us;
            check_equal(data_out, '0', "Check after falling edge");
            for d in 0 to rnd.RandInt(50) loop
                wait for 2 us;
                check_equal(data_out, '0', "Check wait low");
            end loop;
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
