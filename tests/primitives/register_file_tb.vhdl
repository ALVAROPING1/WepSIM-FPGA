context work.tb_context;

use src.utils.std_ulogic_matrix;
use src.utils.unsigned_vector;

use work.utils;

entity RegisterFile_TB is
    generic (
        runner_cfg: string;
        size, addr_size, read_outputs: positive
    );
end;

architecture tb of RegisterFile_TB is
    signal w_addr: unsigned(addr_size - 1 downto 0);
    signal w_data: std_ulogic_vector(size - 1 downto 0);
    signal r_addr: unsigned_vector(0 to read_outputs - 1)(addr_size - 1 downto 0);
    signal r_data: std_ulogic_matrix(0 to read_outputs - 1)(size - 1 downto 0);
    signal clk, rst, w: std_ulogic := '0';
begin
    dut: entity src.RegisterFile
        generic map(size, addr_size, read_outputs)
        port map(clk, rst, w, w_addr, w_data, r_addr, r_data);

    utils.clk_gen(clk);

    main: process
        variable rnd: RandomPType;
        constant ZERO: std_ulogic_vector(size - 1 downto 0) := (others => '0');
        constant addresses: positive := 2**addr_size;

        type RAMState is array (natural range 0 to addresses - 1) of std_ulogic_vector(w_data'range);
        variable state: RAMState := (others => (others => '0'));
    begin
        test_runner_setup(runner, runner_cfg);
        rst <= '1';
        wait for 1 us;
        rst <= '0';
        for i in 0 to addresses - 1 loop
            r_addr(0) <= to_unsigned(i, addr_size);
            wait for 0.5 us;
            check_equal(r_data(0), ZERO, "Check output after reset");
            wait for 1.5 us;
        end loop;

        for i in 0 to maximum(1000, addresses) loop
            rst <= '1' when rnd.RandInt(0, 20) = 0 else '0';
            w <= '1' when rnd.RandBool else '0';
            w_addr <= rnd.RandUnsigned(addr_size);
            w_data <= rnd.RandSlv(size);

            for r_port in r_addr'range loop
                r_addr(r_port) <= rnd.RandUnsigned(addr_size);
            end loop;
            wait for 0.5 us;
            if rst then
                state := (others => (others => '0'));
            end if;

            for r_port in r_addr'range loop
                check_equal(
                    r_data(r_port), state(to_integer(r_addr(r_port))),
                    "Check read of port " & to_string(r_port)
                );
            end loop;

            wait for 1.5 us;
            if not rst and w then
                state(to_integer(w_addr)) := w_data;
            end if;
            rst <= '0';
        end loop;

        w <= '0';
        for i in 0 to addresses - 1 loop
            r_addr(0) <= to_unsigned(i, addr_size);
            wait for 0.5 us;
            check_equal(r_data(0), state(i), "Check output in final state");
            wait for 1.5 us;
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
