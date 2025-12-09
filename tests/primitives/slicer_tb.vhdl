context work.tb_context;

entity Slicer_TB is
    generic (
        runner_cfg: string;
        offset_size, out_size: positive;
    );
end;

architecture tb of Slicer_TB is
    signal data_in: std_ulogic_vector(2**offset_size - 1 downto 0);
    signal data_out: std_ulogic_vector(out_size - 1 downto 0);
    signal offset: unsigned(offset_size - 1 downto 0);
begin
    dut: entity src.Slicer generic map(offset_size, out_size) port map(data_in, data_out, offset);

    main: process
        variable rnd: RandomPType;
        variable value: std_ulogic_vector(data_in'range);
        variable v_offset: natural;
    begin
        test_runner_setup(runner, runner_cfg);
        for iteration in 0 to 1000 loop
            data_in <= rnd.RandSlv(data_in'high + 1);
            offset <= rnd.RandUnsigned(offset_size);
            wait for 1 ns;
            v_offset := to_integer(offset);
            value := data_in srl v_offset;
            check_equal(data_out, value(out_size - 1 downto 0));
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
