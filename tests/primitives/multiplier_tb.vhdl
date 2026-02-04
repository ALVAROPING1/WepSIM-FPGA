context work.tb_context;

use src.utils.maybe_signed;

entity Multiplier_TB is
    generic (
        runner_cfg: string;
        size: positive
    );
end;

architecture tb of Multiplier_TB is
    signal a, b: std_ulogic_vector(size - 1 downto 0);
    signal c: signed(size * 2 - 1 downto 0);
    signal signed_a, signed_b, overflow: std_ulogic;
begin
    dut: entity src.Multiplier generic map(size) port map(a, b, signed_a, signed_b, c, overflow);

    main: process
        variable rnd: RandomPType;
        variable res: signed(size * 2 - 1 downto 0);
        variable int_a, int_b: integer;
    begin
        test_runner_setup(runner, runner_cfg);
        for iteration in 0 to 2000 loop
            a <= rnd.RandSlv(size);
            b <= rnd.RandSlv(size);
            for signs in 0 to 3 loop
                signed_a <= to_unsigned(signs, 2)(0);
                signed_b <= to_unsigned(signs, 2)(1);
                wait for 1 ns;
                int_a := to_integer(maybe_signed(a, signed_a));
                int_b := to_integer(maybe_signed(b, signed_b));
                res := to_signed(int_a * int_b, size * 2);
                info("Operation: " & to_string(int_a) & " * " & to_string(int_b));
                check_equal(c, res, "Check result");
                check_equal(overflow, resize(res, size) /= res, "Check overflow");
            end loop;
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
