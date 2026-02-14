context work.tb_context;

use work.utils;

entity FIFO_TB is
    generic (
        runner_cfg: string;
        size, capacity: positive
    );
end entity;

architecture tb of FIFO_TB is
    signal clk, r, w: std_ulogic := '0';
    signal w_data, r_data: std_ulogic_vector(size - 1 downto 0) := (others => '0');
    signal full, empty, almost_full, almost_empty: std_ulogic := '0';
    signal contents: src.utils.std_ulogic_matrix(1 to capacity)(w_data'range) := (others => (others => '0'));
    constant AF: natural := maximum(capacity - 2, 0);
    constant AE: natural := minimum(2, capacity);
begin
    dut: entity src.FIFO
        generic map (size, capacity, AF, AE)
        port map(clk, r, w, w_data, r_data, full, empty, almost_full, almost_empty);

    utils.clk_gen(clk);

    main: process
        variable rnd: RandomPType;
        variable curr, value: std_ulogic_vector(w_data'range);
        constant ZERO: std_ulogic_vector(w_data'range) := (others => '0');
        variable count: natural := 0;
    begin
        test_runner_setup(runner, runner_cfg);
        wait for 1 us;
        for l in 1 to 5 loop
            contents <= (others => (others => '0'));
            info("Start loop");
            if run("serial r/w") then
                check_equal(r_data, ZERO, "Check tail of empty FIFO");
                check_equal(full, '0', "Check full status of empty FIFO");
                check_equal(empty, '1', "Check empty status of empty FIFO");
                check_equal(almost_full, '0', "Check almost full status of empty FIFO");
                check_equal(almost_empty, '1', "Check almost empty status of empty FIFO");
                info("  Start Push");
                w <= '1';
                for i in 1 to capacity + rnd.RandInt(0, 5) loop
                    if i <= capacity then
                        curr := rnd.RandSlv(size);
                        contents(i) <= curr;
                        w_data <= curr;
                    end if;
                    wait for 2 us;
                    check_equal(r_data, contents(1), "Check tail while pushing");
                    check_equal(full, i >= capacity, "Check full status while pushing");
                    check_equal(empty, '0', "Check empty status while pushing");
                    check_equal(almost_full, i > AF, "Check almost full status while pushing");
                    check_equal(almost_empty, i < AE, "Check almost empty status while pushing");
                end loop;
                w <= '0';
                wait for 2 us * rnd.RandInt(0, 3);
                info("  Start Pop");
                r <= '1';
                for i in capacity - 1 downto -rnd.RandInt(0, 5) loop
                    wait for 2 us;
                    value := contents(capacity - i + 1) when i >= 1 else (others => '0');
                    check_equal(r_data, value, "Check tail while popping");
                    check_equal(full, '0', "Check full status while popping");
                    check_equal(empty, i <= 0, "Check empty status while popping");
                    check_equal(almost_full, i > AF, "Check almost full status while popping");
                    check_equal(almost_empty, i < AE, "Check almost empty status while popping");
                end loop;
                r <= '0';
            elsif run("concurrent r/w") then
                w <= '1';
                info("  Start slow push");
                for i in 1 to capacity loop
                    curr := rnd.RandSlv(size);
                    w_data <= curr;
                    contents(i) <= curr;
                    wait for 2 us;
                    r <= '1';
                    for r in 0 to capacity * 2 - 1 loop
                        check_equal(r_data, contents(r mod capacity + 1), "Check tail");
                        check_equal(full, i = capacity, "Check full status");
                        check_equal(empty, '0', "Check empty status");
                        check_equal(almost_full, i > AF, "Check almost full status");
                        check_equal(almost_empty, i < AE, "Check almost empty status");
                        curr := rnd.RandSlv(size);
                        w_data <= curr;
                        contents((i + r) mod capacity + 1) <= curr;
                        wait for 2 us;
                    end loop;
                    r <= '0';
                end loop;
                w <= '0';
                wait for 2 us * rnd.RandInt(0, 3);
                info("  Start slow pop");
                r <= '1';
                count := capacity;
                for i in 1 to capacity - 1 loop
                    check_equal(r_data, contents(i), "Check tail");
                    check_equal(full, count = capacity, "Check full status");
                    check_equal(empty, '0', "Check empty status");
                    check_equal(almost_full, count > AF, "Check almost full status");
                    check_equal(almost_empty, count < AE, "Check almost empty status");
                    count := count - 1;
                    wait for 2 us;
                    w <= '1';
                    for r in 0 to capacity * 2 - 1 loop
                        check_equal(r_data, contents((i + r) mod capacity + 1), "Check tail");
                        check_equal(full, count = capacity, "Check full status");
                        check_equal(empty, '0', "Check empty status");
                        check_equal(almost_full, count > AF, "Check almost full status");
                        check_equal(almost_empty, count < AE, "Check almost empty status");
                        curr := rnd.RandSlv(size);
                        w_data <= curr;
                        contents(r mod capacity + 1) <= curr;
                        wait for 2 us;
                    end loop;
                    w <= '0';
                end loop;
                check_equal(r_data, contents(capacity), "Check tail");
                check_equal(full, 1 = capacity, "Check full status");
                check_equal(empty, '0', "Check empty status");
                check_equal(almost_full, 1 > AF, "Check almost full status");
                check_equal(almost_empty, 1 < AE, "Check almost empty status");
                wait for 2 us;
                check_equal(r_data, ZERO, "Check tail");
                check_equal(full, '0', "Check full status");
                check_equal(empty, '1', "Check empty status");
                check_equal(almost_full, '0', "Check almost full status");
                check_equal(almost_empty, '1', "Check almost empty status");
                r <= '0';
            end if;
            wait for 2 us * rnd.RandInt(0, 3);
        end loop;
        test_runner_cleanup(runner);
    end process;
end architecture;
