context work.tb_context;

entity ALU_TB is
    generic (
        runner_cfg: string
    );
end;

architecture tb of ALU_TB is
    constant size: positive := 4;
    signal a, b: std_ulogic_vector(size - 1 downto 0);
    signal opcode: std_ulogic_vector(4 downto 0);
    signal res: std_ulogic_vector(size - 1 downto 0);
    signal carry, overflow, negative, zero: std_ulogic;
begin
    dut: entity src.ALU generic map(size) port map(a, b, opcode, res, carry, overflow, negative, zero);

    main: process
    begin
        test_runner_setup(runner, runner_cfg);
        a <= "0110";
        b <= "0011";
        opcode <= "00000";
        wait for 1 us;
        opcode <= "00001";
        wait for 1 us;
        opcode <= "00010";
        wait for 1 us;
        opcode <= "00011";
        wait for 1 us;
        opcode <= "00100";
        wait for 1 us;
        opcode <= "00101";
        wait for 1 us;
        opcode <= "00110";
        wait for 1 us;
        opcode <= "00111";
        wait for 1 us;
        opcode <= "01000";
        wait for 1 us;
        opcode <= "01001";
        wait for 1 us;
        opcode <= "01010";
        wait for 1 us;
        opcode <= "01011";
        wait for 1 us;
        opcode <= "01100";
        wait for 1 us;
        test_runner_cleanup(runner);
    end process;
end;
