context work.tb_context;

use src.utils.unsigned_vector;
use work.utils;

entity ImmediateDecoder_TB is
    generic (
        offset_size: positive;
        runner_cfg: string
    );
end;

architecture tb of ImmediateDecoder_TB is
    signal data_in, data_out: std_ulogic_vector(2**offset_size - 1 downto 0);
    signal offset, size: unsigned(offset_size - 1 downto 0);
    signal sign_extend: std_logic;

    pure function null_map(a: natural; d: std_ulogic_vector) return std_ulogic_vector is
    begin
        return (d'range => '0');
    end;
begin
    dut: entity src.ImmediateDecoder 
        generic map (offset_size, null_map)
        port map(data_in, data_out, offset, size, sign_extend);

    main: process
        variable rnd: RandomPType;
        variable low, high: natural range data_in'range;
        variable res: std_ulogic_vector(data_out'range);
    begin
        test_runner_setup(runner, runner_cfg);
        for i in 1 to 1000 loop
            res := (others => '0');
            data_in <= rnd.RandSlv(data_in'high + 1);
            low := rnd.RandInt(0, low'high);
            high := rnd.RandInt(low, minimum(low + low'high - 1, high'high));
            offset <= to_unsigned(low, offset'high + 1);
            size <= to_unsigned(high - low + 1, size'high + 1);
            sign_extend <= '0';
            wait for 2 us;
            res(to_integer(size) - 1 downto 0) := data_in(high downto low);
            check_equal(data_out, res, "Check result (unsigned)");
            sign_extend <= '1';
            wait for 2 us;
            res(res'high downto to_integer(size)) := (others => data_in(high));
            check_equal(data_out, res, "Check result (unsigned)");
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
