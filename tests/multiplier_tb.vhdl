context work.tb_context;

entity Multiplier_TB is
    generic (
        runner_cfg: string;
        size: positive
    );
end;

architecture tb of Multiplier_TB is
    signal a, b: signed(size - 1 downto 0);
    signal c: signed(size * 2 - 1 downto 0);
    signal overflow: std_ulogic;
begin
    dut: entity src.Multiplier generic map(size) port map(a, b, c, overflow);

    main: process
        variable rnd: RandomPType;
        variable res: integer;
        variable res_signed: signed(size * 2 - 1 downto 0);
        variable sign_bit: signed(size downto 0);
    begin
        test_runner_setup(runner, runner_cfg);
        for iteration in 0 to 2000 loop
            a <= rnd.RandSigned(size);
            b <= rnd.RandSigned(size);
            wait for 1 ns;
            res := to_integer(a) * to_integer(b);
            res_signed := to_signed(res, size * 2);
            check_equal(c, res_signed, "Check result of operation");
            sign_bit := (others => res_signed(res_signed'high));
            check_equal(overflow, res_signed(size * 2 - 1 downto size - 1) /= sign_bit, "Check overflow result");
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
