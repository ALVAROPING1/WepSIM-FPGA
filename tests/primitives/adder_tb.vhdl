context work.tb_context;

entity Adder_TB is
    generic (
        runner_cfg: string;
        size: positive
    );
end;

architecture tb of Adder_TB is
    signal a, b, c: signed(size - 1 downto 0);
    signal overflow, carry, subtraction, signed_arith: std_ulogic;
begin
    dut: entity src.Adder generic map(size) port map(std_ulogic_vector(a), std_ulogic_vector(b), c, subtraction, signed_arith, overflow, carry);

    main: process
        variable rnd: RandomPType;
        variable res, int_a, int_b: integer;
        variable res_signed: signed(size downto 0);
        variable op: string(1 to 3);
        variable signed_op: string(1 to 11);
    begin
        test_runner_setup(runner, runner_cfg);
        for iteration in 0 to 2000 loop
            a <= rnd.RandSigned(size);
            b <= rnd.RandSigned(size);
            subtraction <= '1' when rnd.RandBool else '0';
            signed_arith <= '1' when rnd.RandBool else '0';
            wait for 1 ns;
            op := " - " when subtraction else " + ";
            signed_op := " (signed)  " when signed_arith else " (unsigned)";
            int_a := to_integer(a) when signed_arith else to_integer(unsigned(a));
            int_b := to_integer(b) when signed_arith else to_integer(unsigned(b));
            info("Operation: " & to_string(int_a) & op & to_string(int_b) & signed_op);
            res := int_a - int_b when subtraction else int_a + int_b;
            check_equal(c, to_signed(res, size), "Check result");
            res_signed := to_signed(res, size + 1);
            check_equal(overflow, resize(res_signed, size) /= res_signed, "Check overflow");
            check_equal(carry, res < 0 or res > 2**size - 1, "Check carry");
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
