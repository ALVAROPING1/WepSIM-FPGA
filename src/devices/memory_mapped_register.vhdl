library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MemoryMappedReg is
    generic(size: positive; reg_addr: unsigned(15 downto 0));
    port(
        clk, iow: in std_ulogic;
        addr: in unsigned(15 downto 0);
        data_in: in std_ulogic_vector(size - 1 downto 0);
        data_out: out std_ulogic_vector(size - 1 downto 0);
    );
end;

architecture behaviour of MemoryMappedReg is
    signal update: std_ulogic := '0';
begin
    reg: entity work.Reg generic map (size) port map (clk, update, data_in, data_out);
    update <= '1' when iow = '1' and addr = reg_addr else '0';
end;
