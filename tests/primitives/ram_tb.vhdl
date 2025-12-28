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
    signal clk, w, r, se: std_ulogic := '0';
    signal bw: std_ulogic_vector(1 downto 0) := "11";
begin
    dut: entity src.RAM generic map(size, addr_size) port map(clk, w, r, se, bw, addr, data);

    utils.clk_gen(clk);

    main: process
        variable rnd: RandomPType;
        constant ZERO: std_ulogic_vector(size - 1 downto 0) := (others => '0');
        constant Z: std_ulogic_vector(size - 1 downto 0) := (others => 'Z');
        constant ADDRESSES: positive := 2**(addr_size - 2);

        variable state: std_ulogic_vector(ADDRESSES * size - 1 downto 0) := (others => '0');
        variable bits, word_addr, offset, high: natural;
        variable v_bw: std_ulogic_vector(bw'range);
        variable v_addr: unsigned(addr'range);
    begin
        test_runner_setup(runner, runner_cfg);
        wait for 1 us;
        r <= '1';
        for i in 0 to ADDRESSES - 1 loop
            addr <= to_unsigned(i, addr_size);
            wait for 2 us;
            check_equal(data, ZERO, "Check output initialization");
        end loop;

        for i in 0 to maximum(1000, ADDRESSES) loop
            v_addr := rnd.RandUnsigned(addr_size);
            v_bw := rnd.RandSlv(2);
            addr <= v_addr;
            bw <= v_bw;
            with v_bw select
                bits := size/4 when "00",
                        size/2 when "01",
                        size   when others;
            with v_bw select
                offset := to_integer(v_addr(1 downto 0)) * bits when "00",
                          to_integer(v_addr(1 downto 1)) * bits when "01",
                          0                                   when others;
            word_addr := to_integer(v_addr(v_addr'high downto 2)) * size + offset;
            high := word_addr + bits - 1;
            case rnd.RandInt(0, 2) is
                when 0 => -- Write
                    w <= '1'; r <= '0';
                    data <= rnd.RandSlv(size);
                    wait for 2 us;
                    state(high downto word_addr) := data(bits - 1 downto 0);
                    data <= Z;
                when 1 => -- Read
                    w <= '0'; r <= '1';
                    wait for 2 us;
                    check_equal(data, resize(unsigned(state(high downto word_addr)), data'high + 1), "Check output after read (unsigned)");
                    se <= '1';
                    wait for 2 us;
                    check_equal(signed(data), resize(signed(state(high downto word_addr)), data'high + 1), "Check output after read (signed)");
                    se <= '0';
                when others => -- No-op
                    w <= '0'; r <= '0';
                    wait for 2 us;
                    check_equal(data, Z, "Check output after no-op");
            end case;
        end loop;

        w <= '0'; r <= '1'; bw <= "11";
        for i in 0 to ADDRESSES - 1 loop
            addr <= to_unsigned(i, addr_size - 2) & "00";
            wait for 2 us;
            check_equal(data, state((i+1) * size - 1 downto i * size), "Check output in final state");
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
