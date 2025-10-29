library vunit_lib;
context vunit_lib.vunit_context;

library osvvm;
use osvvm.RandomPkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src;
use src.utils.std_ulogic_matrix;

entity Demultiplexer_TB is
    generic (
        runner_cfg: string;
        size, addresses: positive
    );
end;

architecture tb of Demultiplexer_TB is
    signal data_in: std_ulogic_vector(size - 1 downto 0);
    signal data_out: std_ulogic_matrix(0 to addresses - 1)(size - 1 downto 0);
    signal sel: natural range 0 to addresses - 1;
begin
    dut: entity src.Demultiplexer generic map(size, addresses) port map(data_in, data_out, sel);

    main: process
        variable rnd: RandomPType;
        constant Z: std_ulogic_vector(size - 1 downto 0) := (others => 'Z');
    begin
        test_runner_setup(runner, runner_cfg);
        for iteration in 0 to 1000 loop
            data_in <= rnd.RandSlv(size);
            sel <= rnd.RandInt(0, addresses - 1);
            wait for 1 ns;
            for i in data_out'range loop
                if i = sel then
                    check_equal(data_out(i), data_in, "Check selected output " & to_string(i));
                else
                    check_equal(data_out(i), Z, "Check unselected output " & to_string(i));
                end if;
            end loop;
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
