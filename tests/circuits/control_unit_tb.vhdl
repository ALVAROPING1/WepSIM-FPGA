context work.tb_context;

use work.utils;

entity ControlUnit_TB is
    generic (
        runner_cfg: string
    );
end;

architecture tb of ControlUnit_TB is
    constant size: positive := 32;
    signal clk: std_ulogic;
    signal int, io_rdy, m_rdy: std_ulogic := '0';
    signal instruction, state: std_ulogic_vector(size - 1 downto 0) := (others => '0');
begin
    dut: entity src.ControlUnit generic map (size) port map (
        clk, '0', '1',
        int, io_rdy, m_rdy,
        instruction, state,
        open, open
    );

    utils.clk_gen(clk);

    main: process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for 9 us;
        instruction <= "00000000000000000000000000110011";
        wait for 50 us;
        test_runner_cleanup(runner);
    end process;
end;
