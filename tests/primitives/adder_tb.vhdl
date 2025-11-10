context work.tb_context;

entity Adder_TB is
    generic (
        runner_cfg: string;
        size: positive
    );
end;

architecture tb of Adder_TB is
    signal a, b, c: signed(size - 1 downto 0);
    signal overflow, subtraction: std_ulogic;
begin
    dut: entity src.Adder generic map(size) port map(a, b, c, subtraction, overflow);

    main: process
        variable rnd: RandomPType;
        variable res: integer;
        variable res_signed: signed(size downto 0);
        variable op: string(1 to 3);
    begin
        test_runner_setup(runner, runner_cfg);
        for iteration in 0 to 2000 loop
            a <= rnd.RandSigned(size);
            b <= rnd.RandSigned(size);
            wait for 1 ns;
            if run("addition") then
                res := to_integer(a) + to_integer(b);
                subtraction <= '0';
                op := " + ";
            elsif run("subtraction") then
                res := to_integer(a) - to_integer(b);
                subtraction <= '1';
                op := " - ";
            end if;
            info("Operation: " & to_string(to_integer(a)) & op & to_string(to_integer(b)));
            wait for 1 ns;
            check_equal(c, to_signed(res, size), "Check result");
            res_signed := to_signed(res, size + 1);
            check_equal(overflow, resize(res_signed, size) /= res_signed, "Check overflow");
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
