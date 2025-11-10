context work.tb_context;

entity Source_TB is
    generic (
        runner_cfg: string;
        size: positive;
        value: natural
    );
end;

architecture tb of Source_TB is
    constant val: std_ulogic_vector(size - 1 downto 0) := std_ulogic_vector(to_unsigned(value, size));
    signal res: std_ulogic_vector(val'range);
begin
    dut: entity src.Source generic map(val) port map(res);

    main: process
    begin
        test_runner_setup(runner, runner_cfg);
        check_equal(res, val);
        test_runner_cleanup(runner);
    end process;
end;
