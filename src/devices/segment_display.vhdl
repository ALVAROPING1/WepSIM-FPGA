library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SegmentDisplay is
    port(
        clk, iow, ior, run: in std_ulogic;
        addr: in unsigned(15 downto 0);
        data: inout std_logic_vector(31 downto 0);
        debug_data: in std_ulogic_vector(31 downto 0);
        segment: out std_ulogic_vector(7 downto 0);
        enable: out std_ulogic_vector(7 downto 0)
    );
end;

architecture behaviour of SegmentDisplay is
    signal display_hex: std_ulogic;
    signal data_segments: std_ulogic_vector(63 downto 0) := (others => '0');
    signal display_data: std_ulogic_vector(31 downto 0) := (others => '0');
    signal curr_segment: std_ulogic_vector(7 downto 0);
    signal idx: natural range 0 to 7 - 1;
begin
    mode_reg: entity work.MemoryMappedReg generic map (1,  x"5100") port map (clk, iow, ior, addr, data(0) => data(0), data_out(0) => display_hex);
    low_reg:  entity work.MemoryMappedReg generic map (32, x"5104") port map (clk, iow, ior, addr, data, display_data);
    high_reg: entity work.MemoryMappedReg generic map (32, x"5108") port map (clk, iow, ior, addr, data, data_segments(63 downto 32));

    data_sel: entity work.Multiplexer generic map (32, 1) port map ((debug_data, display_data), data_segments(31 downto 0), sel(0) => run);

    display:  entity work.SegmentDisplayController generic map (8) port map (clk, not run or display_hex, data_segments, curr_segment, idx);

    enable <= not ("00000001" sll idx);
    segment <= not curr_segment;
end;
