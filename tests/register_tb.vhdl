library vunit_lib;
context vunit_lib.vunit_context;

library osvvm;
use osvvm.RandomPkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src;

use work.utils;

entity Reg_TB is
    generic (
        runner_cfg: string;
        size: positive
    );
end;

architecture tb of Reg_TB is
    signal data_in, data_out: std_ulogic_vector(size - 1 downto 0);
    signal clk, rst, w: std_ulogic;
begin
    dut: entity src.Reg generic map(size) port map(clk, rst, w, data_in, data_out);

    utils.clk_gen(clk);

    main: process
        variable rnd: RandomPType;
        variable prev: std_ulogic_vector(size - 1 downto 0) := (others => '0');
        constant ZERO: std_ulogic_vector(size - 1 downto 0) := (others => '0');
    begin
        test_runner_setup(runner, runner_cfg);
        rst <= '1';
        wait for 1 us;
        check_equal(data_out, ZERO, "Check output after reset");
        for i in 0 to 1000 loop
            data_in <= rnd.RandSlv(size);
            rst <= '1' when rnd.RandInt(0, 20) = 0 else '0';
            w <= '1' when rnd.RandInt(0, 3) = 0 else '0';
            wait for 2 us;
            if rst then
                check_equal(data_out, ZERO, "Check output after reset");
                prev := ZERO;
            elsif w then
                check_equal(data_out, data_in, "Check output after write");
                prev := data_in;
            else
                check_equal(data_out, prev, "Check output after no-op");
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
