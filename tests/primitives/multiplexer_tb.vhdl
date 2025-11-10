context work.tb_context;

use src.utils.std_ulogic_matrix;

entity Multiplexer_TB is
    generic (
        runner_cfg: string;
        size, addr_size: positive
    );
end;

architecture tb of Multiplexer_TB is
    signal data_in: std_ulogic_matrix(0 to 2**addr_size - 1)(size - 1 downto 0);
    signal data_out: std_ulogic_vector(size - 1 downto 0);
    signal sel: unsigned(addr_size - 1 downto 0);
begin
    dut: entity src.Multiplexer generic map(size, addr_size) port map(data_in, data_out, sel);

    main: process
        variable rnd: RandomPType;
    begin
        test_runner_setup(runner, runner_cfg);
        for iteration in 0 to 1000 loop
            for i in data_in'range loop
                data_in(i) <= rnd.RandSlv(size);
            end loop;
            sel <= rnd.RandUnsigned(addr_size);
            wait for 1 ns;
            for i in data_in'range loop
                info("Input[" & to_string(i) & "]: " & to_string(data_in(i)));
            end loop;
            info("Selected: " & to_string(to_integer(sel)));
            check_equal(data_out, data_in(to_integer(sel)));
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
