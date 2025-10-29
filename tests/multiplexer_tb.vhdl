context work.tb_context;

use src.utils.std_ulogic_matrix;

entity Multiplexer_TB is
    generic (
        runner_cfg: string;
        size, addresses: positive
    );
end;

architecture tb of Multiplexer_TB is
    signal data_in: std_ulogic_matrix(0 to addresses - 1)(size - 1 downto 0);
    signal data_out: std_ulogic_vector(size - 1 downto 0);
    signal sel: natural range 0 to addresses - 1;
begin
    dut: entity src.Multiplexer generic map(size, addresses) port map(data_in, data_out, sel);

    main: process
        variable rnd: RandomPType;
    begin
        test_runner_setup(runner, runner_cfg);
        for iteration in 0 to 1000 loop
            for i in data_in'range loop
                data_in(i) <= rnd.RandSlv(size);
            end loop;
            sel <= rnd.RandInt(0, addresses - 1);
            wait for 1 ns;
            check_equal(data_out, data_in(sel));
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
