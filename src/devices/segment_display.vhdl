library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SegmentDisplay is
    generic(size: positive);
    port(
        clk, iow, ior: in std_ulogic;
        addr: in unsigned(15 downto 0);
        data: inout std_logic_vector(size - 1 downto 0);
        segment: out std_ulogic_vector(7 downto 0);
        enable: out std_ulogic_vector(7 downto 0)
    );
end;

architecture behaviour of SegmentDisplay is
    signal display_hex: std_ulogic;
    signal data_low, data_high: std_ulogic_vector(data'range) := (others => '0');
    signal curr_segment: std_ulogic_vector(7 downto 0);
    signal idx: natural range 0 to size - 1;
begin
    mode_reg: entity work.MemoryMappedReg generic map (1, x"5100")    port map (clk, iow, ior, addr, data(0) => data(0), data_out(0) => display_hex);
    low_reg:  entity work.MemoryMappedReg generic map (size, x"5104") port map (clk, iow, ior, addr, data, data_low);
    high_reg: entity work.MemoryMappedReg generic map (size, x"5108") port map (clk, iow, ior, addr, data, data_high);

    display:  entity work.SegmentDisplayController generic map (8) port map (acc(acc'high), display_hex, data_high & data_low, curr_segment, idx);

    enable <= not ("00000001" sll idx);
    segment <= not curr_segment;
end;
