library vunit_lib;
context vunit_lib.vunit_context;

library osvvm;
use osvvm.RandomPkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src;

use work.utils;

entity RAM_TB is
    generic (
        runner_cfg: string;
        size, addresses: positive
    );
end;

architecture tb of RAM_TB is
    signal addr: natural range 0 to addresses - 1;
    signal data: std_logic_vector(size - 1 downto 0) := (others => 'Z');
    signal clk, rst, w, r: std_ulogic := '0';
begin
    dut: entity src.RAM generic map(size, addresses) port map(clk, rst, w, r, addr, data);

    utils.clk_gen(clk);

    main: process
        variable rnd: RandomPType;
        variable op, prev_op: natural;
        constant ZERO: std_ulogic_vector(size - 1 downto 0) := (others => '0');
        constant Z: std_ulogic_vector(size - 1 downto 0) := (others => 'Z');

        type RAMState is array (natural range 0 to addresses - 1) of std_ulogic_vector(data'range);
        variable state: RAMState := (others => (others => '0'));
    begin
        test_runner_setup(runner, runner_cfg);
        rst <= '1';
        wait for 1 us;
        rst <= '0';
        r <= '1';
        for i in 0 to addresses - 1 loop
            addr <= i;
            wait for 2 us;
            check_equal(data, ZERO, "Check output after reset");
        end loop;
        prev_op := 1;

        for i in 0 to maximum(1000, addresses) loop
            op := rnd.RandInt(0, 2);
            if op = 0 then -- Write
                -- If bus was in use, free it before using it
                if prev_op = 1 then
                    w <= '0'; r <= '0';
                    wait for 2 us;
                    check_equal(data, Z, "Check output after no-op");
                end if;
                prev_op := op;
                w <= '1'; r <= '0';
                addr <= rnd.RandInt(0, addresses - 1);
                data <= rnd.RandSlv(size);
                wait for 2 us;
                state(addr) := data;
                data <= Z;
            elsif op = 1 then -- Read
                prev_op := op;
                w <= '0'; r <= '1';
                addr <= rnd.RandInt(0, addresses - 1);
                wait for 2 us;
                check_equal(data, state(addr), "Check output after read");
            else -- No-op
                prev_op := op;
                w <= '0'; r <= '0';
                addr <= rnd.RandInt(0, addresses - 1);
                wait for 2 us;
                check_equal(data, Z, "Check output after no-op");
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
