context work.tb_context;

use work.utils;

entity RAM_TB is
    generic (
        runner_cfg: string;
        size, addr_size: positive
    );
end;

architecture tb of RAM_TB is
    signal addr: unsigned(addr_size - 1 downto 0);
    signal data: std_logic_vector(size - 1 downto 0) := (others => 'Z');
    signal clk, rst, w, r: std_ulogic := '0';
begin
    dut: entity src.RAM generic map(size, addr_size) port map(clk, rst, w, r, addr, data);

    utils.clk_gen(clk);

    main: process
        variable rnd: RandomPType;
        constant ZERO: std_ulogic_vector(size - 1 downto 0) := (others => '0');
        constant Z: std_ulogic_vector(size - 1 downto 0) := (others => 'Z');
        constant ADDRESSES: positive := 2**addr_size;

        type RAMState is array (natural range 0 to ADDRESSES - 1) of std_ulogic_vector(data'range);
        variable state: RAMState := (others => (others => '0'));
    begin
        test_runner_setup(runner, runner_cfg);
        rst <= '1';
        wait for 1 us;
        rst <= '0';
        r <= '1';
        for i in 0 to ADDRESSES - 1 loop
            addr <= to_unsigned(i, addr_size);
            wait for 2 us;
            check_equal(data, ZERO, "Check output after reset");
        end loop;

        for i in 0 to maximum(1000, ADDRESSES) loop
            addr <= rnd.RandUnsigned(addr_size);
            case rnd.RandInt(0, 2) is
                when 0 => -- Write
                    w <= '1'; r <= '0';
                    data <= rnd.RandSlv(size);
                    wait for 2 us;
                    state(to_integer(addr)) := data;
                    data <= Z;
                when 1 => -- Read
                    w <= '0'; r <= '1';
                    wait for 2 us;
                    check_equal(data, state(to_integer(addr)), "Check output after read");
                when others => -- No-op
                    w <= '0'; r <= '0';
                    wait for 2 us;
                    check_equal(data, Z, "Check output after no-op");
            end case;
        end loop;

        w <= '0'; r <= '1';
        for i in 0 to ADDRESSES - 1 loop
            addr <= to_unsigned(i, addr_size);
            wait for 2 us;
            check_equal(data, state(i), "Check output in final state");
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
