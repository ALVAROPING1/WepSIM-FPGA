context work.tb_context;

use work.utils;

entity ClkDivider_TB is
    generic(
        runner_cfg: string;
        in_freq, out_freq: positive
    );
end entity;

architecture tb of ClkDivider_TB is
    signal clk_in, clk_out, clk_out_ref, clk_out_ref_prev: std_ulogic := '0';
begin
    dut: entity src.ClkDivider
        generic map (in_freq, out_freq)
        port map(clk_in, clk_out);

    utils.clk_gen(clk_in);
    utils.clk_gen(clk_out_ref, period => 2 us * real(in_freq) / real(out_freq));

    main: process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for 0.001 us;
        for i in 1 to 200000 loop
            check_equal(clk_out, not clk_out_ref_prev and clk_out_ref);
            clk_out_ref_prev <= clk_out_ref;
            wait for 1.998 us;
            if not clk_out_ref then
                clk_out_ref_prev <= '0';
            end if;
            wait for 0.002 us;
        end loop;
        test_runner_cleanup(runner);
    end process;
end architecture;
