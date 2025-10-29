context work.tb_context;

use ieee.math_real.all;

entity BCDDecoder_TB is
    generic (
        runner_cfg: string;
        size: positive
    );
end entity;

architecture tb of BCDDecoder_TB is
    signal data_in: unsigned(size - 1 downto 0) := (others => '0');
    signal data_out: src.bcd.bcd_vector(natural(floor(log10(real(2**size - 1)))) downto 0);
begin
    dut: entity src.BCDDecoder
        generic map (size, output_size => data_out'high + 1)
        port map(data_in, data_out);

    main: process
        variable rnd: RandomPType;
        variable value: natural;
        variable curr: natural;
    begin
        test_runner_setup(runner, runner_cfg);
        for i in 0 to 1000 loop
            value := rnd.RandInt(0, 2**size - 1);
            curr := value;
            data_in <= to_unsigned(value, size);
            wait for 1 ns;
            for j in data_out'reverse_range loop
                check_equal(data_out(j), curr mod 10, "Check digit " & to_string(i) & " of " & to_string(value));
                curr := curr / 10;
            end loop;
        end loop;
        test_runner_cleanup(runner);
    end process;
end architecture;
