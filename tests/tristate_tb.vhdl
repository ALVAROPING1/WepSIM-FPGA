library vunit_lib;
context vunit_lib.vunit_context;

library osvvm;
use osvvm.RandomPkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src;

entity TriState_TB is
    generic (
        runner_cfg: string;
        size: positive
    );
end;

architecture tb of TriState_TB is
    signal data_in, data_out: std_ulogic_vector(size - 1 downto 0);
    signal enable: boolean;
begin
    dut: entity src.Tristate generic map(size) port map(data_in, data_out, enable);

    main: process
        variable rnd: RandomPType;
        constant Z: std_ulogic_vector(size - 1 downto 0) := (others => 'Z');
    begin
        test_runner_setup(runner, runner_cfg);
        for i in 0 to 1000 loop
            data_in <= rnd.RandSlv(size);
            enable <= true;
            wait for 1 ns;
            check_equal(data_out, data_in);
            enable <= false;
            wait for 1 ns;
            check_equal(data_out, Z);
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
