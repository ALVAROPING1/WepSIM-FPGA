context work.tb_context;

use src.utils.std_ulogic_matrix;
use work.utils;

entity OpcodeDecoder_TB is
    generic (runner_cfg: string);
end;

architecture tb of OpcodeDecoder_TB is
    signal instruction: std_ulogic_vector(7 downto 0);
    signal addr: std_ulogic_vector(3 downto 0);
    signal instruction_exception: std_ulogic;
    constant patterns: std_ulogic_matrix(0 to 15)(instruction'range) := (
        "------01",
        "------10",
        "---11-00",
        "---00100",
        "---10-00",
        "---01-00",
        "---11011",
        "---10-11",
        "---01-11",
        "-0100-11",
        "-1000-11",
        "-0000-11",
        "01100-11",
        "11100111",
        "11100011",
        "11111111"
    );
    constant addrs: std_ulogic_matrix(patterns'range)(addr'range) := (
        "1000",
        "1001",
        "1010",
        "1011",
        "1100",
        "1101",
        "1110",
        "1111",
        "0000",
        "0001",
        "0010",
        "0011",
        "0100",
        "0101",
        "0110",
        "0111"
    );
begin
    dut: entity src.OpcodeDecoder
        generic map (instruction'high + 1, addr'high + 1, patterns, addrs)
        port map(instruction, addr, instruction_exception);

    main: process
        variable curr: instruction'subtype;
    begin
        test_runner_setup(runner, runner_cfg);
        for opcode_i in patterns'range loop
            for iter in 0 to 255 loop
                curr := std_ulogic_vector(to_unsigned(iter, 8));
                if curr ?/= patterns(opcode_i) then
                    next;
                end if;
                instruction <= curr;
                wait for 2 us;
                info("Instruction: " & to_string(instruction) & " (opcode " & to_string(opcode_i) & ")");
                check_equal(instruction_exception, '0', "Check instruction recognized");
                check_equal(addr, addrs(opcode_i), "Check opcode address");
            end loop;
        end loop;
        instruction <= (others => '0');
        wait for 2 us;
        check_equal(instruction_exception, '1', "Check instruction recognized");
        test_runner_cleanup(runner);
    end process;
end;
