context work.tb_context;

entity Boolean_TB is
    generic (
        runner_cfg: string;
        size: positive
    );
end;

architecture tb of Boolean_TB is
    signal data: std_ulogic_vector(size - 1 downto 0);
    signal res_and, res_or, res_xor, res_nand, res_nor, res_xnor: std_ulogic;
begin
    dut_and:  entity src.Boolean generic map(size, "and")  port map(data, res_and);
    dut_or:   entity src.Boolean generic map(size, "or")   port map(data, res_or);
    dut_xor:  entity src.Boolean generic map(size, "xor")  port map(data, res_xor);
    dut_nand: entity src.Boolean generic map(size, "nand") port map(data, res_nand);
    dut_nor:  entity src.Boolean generic map(size, "nor")  port map(data, res_nor);
    dut_xnor: entity src.Boolean generic map(size, "xnor") port map(data, res_xnor);

    main: process
        variable rnd: RandomPType;
        pure function count(data: std_ulogic_vector) return natural is
            variable count: natural := 0;
        begin
            for i in data'range loop
                if data(i) then
                    count := count + 1;
                end if;
            end loop;
            return count;
        end;
    begin
        test_runner_setup(runner, runner_cfg);
        for iteration in 0 to 1000 loop
            data <= rnd.RandSlv(size);
            wait for 1 ns;
            info("Data: " & to_string(data));
            check_equal(res_and,  count(data) = size,    "Check result of AND");
            check_equal(res_or,   count(data) > 0,       "Check result of OR");
            check_equal(res_xor,  count(data) mod 2 = 1, "Check result of XOR");
            check_equal(res_nand, count(data) < size,    "Check result of NAND");
            check_equal(res_nor,  count(data) = 0,       "Check result of NOR");
            check_equal(res_xnor, count(data) mod 2 = 0, "Check result of XNOR");
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
