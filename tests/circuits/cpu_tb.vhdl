context work.tb_context;

use work.utils;

entity Cpu_TB is
    generic (
        runner_cfg: string
    );
end;

architecture tb of Cpu_TB is
    signal clk: std_ulogic;
    signal continue: std_ulogic := '0';
    signal address_bus: std_ulogic_vector(31 downto 0);
    signal data_bus: std_logic_vector(31 downto 0);
    -- signal io_rdy, m_rdy: std_ulogic := '0';
begin
    dut: entity src.Cpu port map (
        clk, '0', continue,
        address_bus, data_bus, open,
        '0', '1', (others => '0'), (others => '0'), open
    );

    utils.clk_gen(clk, period => 10 ns);
    continue <= '1' after 5 ns;

    main: process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for 2000 * 10 * 10 ns;
        test_runner_cleanup(runner);
    end process;
end;
