context work.tb_context;

use work.utils;

entity Timer_TB is
    generic (
        runner_cfg: string;
        size: positive
    );
end entity;

architecture tb of Timer_TB is
    signal clk, iow, inta, int: std_ulogic := '0';
    signal addr: unsigned(15 downto 0);
    signal data, intv: std_ulogic_vector(size - 1 downto 0);
begin
    dut: entity src.Timer
        generic map (size)
        port map(clk, iow, addr, data, inta, int, intv);

    utils.clk_gen(clk);

    main: process
        variable rnd: RandomPType;
        variable length, repeats, id, delay: natural;
        constant Z: std_ulogic_vector(intv'range) := (others => 'Z');
    begin
        test_runner_setup(runner, runner_cfg);
        wait for 1 us;
        for i in 1 to 200 loop
            length := rnd.RandInt(1, minimum(500, 2**size - 1));
            repeats := rnd.RandInt(1, 10);
            id := rnd.RandInt(0, minimum(31, 2**size - 1));
            iow <= '1';
            -- Update id
            addr <= x"1104";
            data <= std_ulogic_vector(to_unsigned(id, size));
            wait for 2 us;
            -- Update length
            addr <= x"1108";
            data <= std_ulogic_vector(to_unsigned(length, size));
            wait for 2 us;
            iow <= '0';
            addr <= (others => 'Z');
            data <= (others => 'Z');
            for j in 1 to repeats loop
                for l in 1 to length loop
                    check_equal(int, '0', "Check timer hasn't triggered yet (flag)");
                    check_equal(intv, Z, "Check timer hasn't triggered yet (id)");
                    wait for 2 us;
                end loop;

                check_equal(int, '1', "Check timer has triggered (flag)");
                check_equal(intv, Z, "Check timer id is waiting");
                wait for 2 us;

                delay := rnd.RandInt(0, 5);
                for d in 1 to delay loop
                    check_equal(int, '1', "Check timer has triggered (flag)");
                    check_equal(intv, Z, "Check timer id is waiting");
                    wait for 2 us;
                end loop;

                inta <= '1';
                wait for 0.5 us;
                check_equal(int, '1', "Check timer has triggered (flag)");
                check_equal(intv, id, "Check timer id is enabled");
                wait for 1 us;
                inta <= '0';
                check_equal(int, '0', "Check timer hasn't triggered yet (flag)");
                check_equal(intv, Z, "Check timer hasn't triggered yet (id)");
                wait for 0.5 us;
            end loop;
        end loop;
        test_runner_cleanup(runner);
    end process;
end architecture;
