library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_pkg.control_bus_signals;

entity Main is
    port (
        clk_in: in std_ulogic;
        step_instruction, continue: in std_ulogic;
        -- io_rdy: in std_ulogic;
        segment: out std_ulogic_vector(7 downto 0);
        enable: out std_ulogic_vector(7 downto 0);
        switches: in std_ulogic_vector(15 downto 1);
        leds: out std_ulogic_vector(15 downto 0);
        -- UART
        rx, cts: in std_ulogic;
        tx, rts: out std_ulogic;
    );
end entity;

architecture rtl of Main is
    constant size: positive := 32;
    signal clk, int, m_rdy: std_ulogic;
    signal device_addr: unsigned(15 downto 0);
    signal debug_data, address_bus: std_ulogic_vector(size - 1 downto 0);
    signal data_bus: std_logic_vector(size - 1 downto 0);
    signal control_bus: control_bus_signals;

    -- vhdl_ls off
    component clk_divider
        port (clk_in: in std_logic; clk_out: out std_logic);
    end component;
    -- vhdl_ls on

    package ram_types is new work.ram_generics generic map(size, 19);
    use ram_types.Contents;

begin
    -- vhdl_ls off
    `if TOOL_TYPE = "SIMULATION" then
        clk <= clk_in;
    `else
        clk_div: clk_divider port map(clk_in, clk);
    `end if
    -- vhdl_ls on

    processor: entity work.Cpu port map (
        clk, step_instruction, continue,
        address_bus, data_bus,
        control_bus,
        int, m_rdy,
        unsigned(switches(15 downto 11)),
        switches(10 downto 9),
        debug_data
    );

    -- ────────────────────────────────── External ──────────────────────────────────

    -- vhdl_ls off
    ram: entity work.RAM
        generic map (ram_types, little_endian => work.firmware.little_endian)
        port map (
            clk,
            control_bus.w, control_bus.r, control_bus.se, control_bus.bw,
            unsigned(address_bus(ram_types.addr_size - 1 downto 0)),
            data_bus,
            m_rdy
        );
    -- vhdl_ls on

    device_addr <= unsigned(address_bus(15 downto 0));

    timer_dev: entity work.Timer generic map (size) port map (
        clk, control_bus.iow, control_bus.ior, control_bus.running,
        device_addr, data_bus,
        control_bus.inta,
        int,
        data_bus
    );

    leds_dev: entity work.MemoryMappedReg generic map (16, x"2000") port map(
        clk, control_bus.iow, control_bus.ior,
        device_addr, data_bus(15 downto 0),
        leds
    );

    switches_dev:
        data_bus <= (15 downto 1 => switches, others => '0')
                    when control_bus.ior = '1' and device_addr = x"2004"
                    else (others => 'Z');

    uart: entity work.UART generic map (size, 25_000_000, 1_500_000) port map (
        clk, control_bus.iow, control_bus.ior,
        device_addr, data_bus, rx, cts, tx, rts
    );

    display_dev: entity work.SegmentDisplay port map (
        clk, control_bus.iow, control_bus.ior, control_bus.running,
        device_addr, data_bus, debug_data,
        segment, enable
    );
end architecture;
