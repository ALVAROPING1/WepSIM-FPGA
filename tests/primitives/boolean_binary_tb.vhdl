context work.tb_context;

entity BooleanBinary_TB is
    generic (
        runner_cfg: string;
        size: positive
    );
end;

architecture tb of BooleanBinary_TB is
    signal a, b: std_ulogic_vector(size - 1 downto 0);
    signal res_and, res_or, res_xor, res_nand, res_nor, res_xnor: std_ulogic_vector(a'range);
begin
    dut_and:  entity src.BooleanBinary generic map(size, "and")  port map(a, b, res_and);
    dut_or:   entity src.BooleanBinary generic map(size, "or")   port map(a, b, res_or);
    dut_xor:  entity src.BooleanBinary generic map(size, "xor")  port map(a, b, res_xor);
    dut_nand: entity src.BooleanBinary generic map(size, "nand") port map(a, b, res_nand);
    dut_nor:  entity src.BooleanBinary generic map(size, "nor")  port map(a, b, res_nor);
    dut_xnor: entity src.BooleanBinary generic map(size, "xnor") port map(a, b, res_xnor);

    main: process
        variable rnd: RandomPType;
    begin
        test_runner_setup(runner, runner_cfg);
        for iteration in 0 to 1000 loop
            a <= rnd.RandSlv(size);
            b <= rnd.RandSlv(size);
            wait for 1 ns;
            info("a: " & to_string(a));
            info("b: " & to_string(b));
            check_equal(res_and,  a and b,  "Check result of AND");
            check_equal(res_or,   a or b,   "Check result of OR");
            check_equal(res_xor,  a xor b,  "Check result of XOR");
            check_equal(res_nand, a nand b, "Check result of NAND");
            check_equal(res_nor,  a nor b,  "Check result of NOR");
            check_equal(res_xnor, a xnor b, "Check result of XNOR");
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
