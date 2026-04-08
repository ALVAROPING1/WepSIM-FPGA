context work.tb_context;

use work.utils;

entity BlockRAM_TB is
    generic (
        runner_cfg: string;
        byte_size, addr_size, n_bytes: positive
    );
end;

architecture tb of BlockRAM_TB is
    constant size: positive := byte_size * n_bytes;
    signal clk: std_ulogic := '0';
    signal data_in, data_out: std_logic_vector(size - 1 downto 0);
    signal addr: unsigned(addr_size - 1 downto 0);
    signal w_enable: std_ulogic_vector(n_bytes - 1 downto 0) := (others => '0');
    constant ADDRESSES: positive := 2**addr_size;
    signal state: std_ulogic_vector(ADDRESSES * size - 1 downto 0) := (others => '0');
begin
    dut: entity src.BlockRAM
        generic map (byte_size, addr_size, n_bytes)
        port map(clk, w_enable, addr, data_in, data_out);

    utils.clk_gen(clk);

    main: process
        variable rnd: RandomPType;
        constant ZERO: std_ulogic_vector(size - 1 downto 0) := (others => '0');

        variable word_addr: natural;
        variable low, high: natural range data_in'range;
    begin
        test_runner_setup(runner, runner_cfg);
        wait for 0.5 us;
        w_enable <= (others => '0');
        for i in 0 to ADDRESSES - 1 loop
            addr <= to_unsigned(i, addr_size);
            wait for 2 us;
            check_equal(data_out, ZERO, "Check output initialization");
        end loop;

        for r in 0 to maximum(1000, ADDRESSES) loop
            w_enable <= rnd.RandSlv(n_bytes);
            addr <= rnd.RandUnsigned(addr_size);
            data_in <= rnd.RandSlv(size);
            wait for 2 us;
            word_addr := to_integer(addr) * size;
            check_equal(data_out, state(word_addr + size - 1 downto word_addr), "Check read output");

            for i in w_enable'range loop
                if w_enable(i) then
                    high := (i+1) * byte_size - 1;
                    low  :=     i * byte_size;
                    state(high + word_addr downto low + word_addr)
                        <= data_in(high downto low);
                end if;
            end loop;
        end loop;

        w_enable <= (others => '0');
        for i in 0 to ADDRESSES - 1 loop
            addr <= to_unsigned(i, addr_size);
            wait for 2 us;
            check_equal(data_out, state((i+1) * size - 1 downto i * size), "Check output in final state");
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
