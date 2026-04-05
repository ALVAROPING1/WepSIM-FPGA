context work.tb_context;

use src.utils.std_ulogic_matrix;
use work.utils;

entity OpcodeDecoder_TB is
    generic (runner_cfg: string);
end;

architecture tb of OpcodeDecoder_TB is
    signal instruction: std_ulogic_vector(7 downto 0);
    signal opcode: unsigned(3 downto 0);
    signal instruction_exception: std_ulogic;
    constant patterns: std_ulogic_matrix(0 to 15)(7 downto 0) := (
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
begin
    dut: entity src.OpcodeDecoder
        generic map (8, 4, patterns)
        port map(instruction, opcode, instruction_exception);

    main: process
        variable curr: instruction'subtype;
    begin
        test_runner_setup(runner, runner_cfg);
        for opcode_i in 0 to 15 loop
            for iter in 0 to 255 loop
                curr := std_ulogic_vector(to_unsigned(iter, 8));
                if curr ?/= patterns(opcode_i) then
                    next;
                end if;
                instruction <= curr;
                wait for 2 us;
                info("Instruction: " & to_string(instruction) & " (opcode " & to_string(opcode_i) & ")");
                check_equal(instruction_exception, '0', "Check instruction recognized");
                check_equal(opcode, to_unsigned(opcode_i, 4), "Check opcode");
            end loop;
        end loop;
        instruction <= (others => '0');
        wait for 2 us;
        check_equal(instruction_exception, '1', "Check instruction recognized");
        test_runner_cleanup(runner);
    end process;
end;
