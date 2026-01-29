context work.tb_context;

use work.utils;

entity MemoryMappedReg_TB is
    generic (
        runner_cfg: string;
        size: positive
    );
end entity;

architecture tb of MemoryMappedReg_TB is
    signal clk, iow, ior: std_ulogic := '0';
    signal addr: unsigned(15 downto 0);
    signal data: std_logic_vector(size - 1 downto 0) := (others => 'Z');
    signal data_out: std_ulogic_vector(size - 1 downto 0);
begin
    dut: entity src.MemoryMappedReg
        generic map (size, x"0100")
        port map(clk, iow, ior, addr, data, data_out);

    utils.clk_gen(clk);

    main: process
        variable rnd: RandomPType;
        constant ZERO: std_ulogic_vector(data'range) := (others => '0');
        constant Z: std_ulogic_vector(data'range) := (others => 'Z');
        variable value: std_ulogic_vector(data'range) := (others => '0');
        variable e: boolean;
    begin
        test_runner_setup(runner, runner_cfg);
        check_equal(data, Z, "Check bus output initialization");
        check_equal(data_out, ZERO, "Check output initialization");
        ior <= '1'; addr <= x"0100";
        wait for 0.5 us;
        check_equal(data, ZERO, "Check bus output initialization");
        check_equal(data_out, ZERO, "Check output initialization");
        ior <= '0';
        wait for 2 us;

        for i in 0 to 1000 loop
            e := rnd.RandBool;
            addr <= x"0100" when e else x"0101";
            case rnd.RandInt(0, 2) is
                when 0 => -- Write
                    iow <= '1'; ior <= '0';
                    data <= rnd.RandSlv(size);
                    wait for 2 us;
                    if e then value := data; end if;
                    data <= Z;
                    check_equal(data_out, value, "Check output after write");
                when 1 => -- Read
                    iow <= '0'; ior <= '1';
                    wait for 2 us;
                    if e then
                        check_equal(data, value, "Check bus output after read");
                    else
                        check_equal(data, Z, "Check bus output after read");
                    end if;
                    check_equal(data_out, value, "Check output after read");
                when others => -- No-op
                    iow <= '0'; ior <= '0';
                    wait for 2 us;
                    check_equal(data, Z, "Check bus output after read");
                    check_equal(data_out, value, "Check output after read");
            end case;
        end loop;
        test_runner_cleanup(runner);
    end process;
end architecture;
