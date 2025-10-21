library vunit_lib;
context vunit_lib.vunit_context;

library osvvm;
use osvvm.RandomPkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src;
use src.bcd.all;

use work.utils;

entity Display7segment_TB is
    generic (
        runner_cfg: string;
        size: positive
    );
end entity;

architecture tb of Display7segment_TB is
    signal clk, rst: std_ulogic;
    signal data_in: bcd_vector(size - 1 downto 0);
    signal segment: std_ulogic_vector(7 downto 0);
    signal enable: natural;
    type digit_table is array (natural range 0 to 9) of std_ulogic_vector(7 downto 0);
    constant tbl: digit_table := (
        "00111111",
        "00000110",
        "01011011",
        "01001111",
        "01100110",
        "01101101",
        "01111101",
        "00000111",
        "01111111",
        "01101111"
    );
begin
    dut: entity src.Display7segment generic map (size) port map(
        clk, rst, data_in, segment, enable
    );

    utils.clk_gen(clk);

    main: process
        variable rnd : RandomPType;
        variable value: bcd_vector(size - 1 downto 0);
    begin
        test_runner_setup(runner, runner_cfg);
        rst <= '1', '0' after 1 us;
        for i in 0 to 3 loop
            for j in value'range loop
                value(j) := rnd.RandInt(0, 9);
            end loop;
            data_in <= value;
            for j in 0 to size - 1 loop
                wait for 1 us;
                check_equal(enable, j, "Check enabled digit");
                check_equal(segment, tbl(value(j)), "Check digit pattern for " & to_string(value(j)));
                wait for 1 us;
            end loop;
        end loop;
        test_runner_cleanup(runner);
    end process;
end architecture;
