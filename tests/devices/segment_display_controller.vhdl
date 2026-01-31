context work.tb_context;

use src.bcd.all;

use work.utils;

entity SegmentDisplayController_TB is
    generic (
        runner_cfg: string;
        digits: positive
    );
end entity;

architecture tb of SegmentDisplayController_TB is
    signal clk, display_hex: std_ulogic;
    signal data_in: std_ulogic_vector(digits * 8 - 1 downto 0);
    signal segment: std_ulogic_vector(7 downto 0);
    signal enable: natural;
    type digit_table is array (natural range 0 to 15) of std_ulogic_vector(7 downto 0);
    constant tbl: digit_table := (
        "00111111",
        "00000110",
        "01011011",
        "01001111",
        "01100110",
        "01101101",
        "01111101",
        "00000111",
        "01111111",
        "01101111",
        "01110111",
        "01111100",
        "00111001",
        "01011110",
        "01111001",
        "01110001"
    );
begin
    dut: entity src.SegmentDisplayController generic map (digits, 1) port map(
        clk, display_hex, data_in, segment, enable
    );

    utils.clk_gen(clk);

    main: process
        variable rnd: RandomPType;
        variable value: std_ulogic_vector(data_in'range);
        variable pattern: std_ulogic_vector(7 downto 0);
    begin
        test_runner_setup(runner, runner_cfg);
        for i in 0 to 250 loop
            for pos in 0 to digits - 1 loop
                value(pos * 8 + 7 downto pos * 8) := rnd.RandSlv(8);
            end loop;
            data_in <= value;
            display_hex <= '1' when rnd.RandBool else '0';
            for r in 1 to rnd.RandInt(1, 20) loop
                for j in 0 to digits - 1 loop
                    wait for 1 us;
                    check_equal(enable, j, "Check enabled digit");
                    if display_hex then
                        pattern := tbl(to_integer(unsigned(value(j * 4 + 3 downto j * 4))));
                    else
                        pattern := value(j * 8 + 7 downto j * 8);
                    end if;
                    check_equal(segment, pattern, "Check digit pattern");
                    wait for 1 us;
                end loop;
            end loop;
        end loop;
        test_runner_cleanup(runner);
    end process;
end architecture;
