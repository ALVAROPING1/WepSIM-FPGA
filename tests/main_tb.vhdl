context work.tb_context;

use work.utils;

entity Main_TB is
    generic (runner_cfg: string);
end entity;

architecture rtl of Main_TB is
    signal clk: std_ulogic;
    signal segment: std_ulogic_vector(7 downto 0);
    signal enable: std_ulogic_vector(7 downto 0);
    signal switches: std_ulogic_vector(15 downto 1);
    signal leds: std_ulogic_vector(15 downto 0);
    -- UART
    signal rx, cts: std_ulogic;
    signal tx, rts: std_ulogic;

    signal pc_send: std_ulogic_vector(7 downto 0);
    signal accepted, iow, clk_e: std_ulogic := '0';

    constant data: src.utils.std_ulogic_matrix(open)(7 downto 0) := (
        -- addr: 0x00000304
        x"04",
        x"03",
        x"00",
        x"00",
        -- size: 0x00000002
        x"02",
        x"00",
        x"00",
        x"00",
        -- data
        -- 0x40302010
        x"10",
        x"20",
        x"30",
        x"40",
        -- 0x80706050
        x"50",
        x"60",
        x"70",
        x"80",

        -- addr: 0x00000008
        x"08",
        x"00",
        x"00",
        x"00",
        -- size: 0x00000001
        x"01",
        x"00",
        x"00",
        x"00",
        -- data
        -- 0x01020304
        x"04",
        x"03",
        x"02",
        x"01",

        -- Stop
        -- addr
        x"00",
        x"00",
        x"00",
        x"00",
        -- size
        x"00",
        x"00",
        x"00",
        x"00",

        -- entrypoint
        x"ff",
        x"00",
        x"ff",
        x"7f"
    );
begin
    dut: entity src.Main port map (
        clk, '0', '1',
        segment, enable,
        switches,
        leds,
        rx, cts,
        tx, rts
    );

    utils.clk_gen(clk, delay_start => 2 us);

    uart_tx: entity src.UARTTX port map (clk, clk_e, iow, rx, rts, pc_send, accepted);

    clk_div: entity src.ClkDivider
        generic map (25_000_000, 1_500_000*8)
        port map (clk, clk_e);

    pc_tx: process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for 1 us;
        iow <= '1';
        for l in data'range loop
            pc_send <= data(l);
            while accepted loop wait for 2 us; end loop;
            while not accepted loop wait for 2 us; end loop;
        end loop;
        iow <= '0';
        wait for 2 us * 1000;
        test_runner_cleanup(runner);
    end process;
end architecture;
