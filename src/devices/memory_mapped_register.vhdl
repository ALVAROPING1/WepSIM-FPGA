library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MemoryMappedReg is
    generic(size: positive; reg_addr: unsigned(15 downto 0));
    port(
        clk, iow, ior: in std_ulogic;
        addr: in unsigned(15 downto 0);
        data: inout std_ulogic_vector(size - 1 downto 0);
        data_out: out std_ulogic_vector(size - 1 downto 0);
    );
end;

architecture behaviour of MemoryMappedReg is
    signal update, e: std_ulogic := '0';
begin
    reg: entity work.Reg generic map (size) port map (clk, update, data, data_out);
    e <= '1' when addr = reg_addr else '0';
    update <= iow and e;
    bus_out: entity work.TriState generic map(size) port map (data_out, data, e and ior and not iow);
end;
