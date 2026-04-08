library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.std_ulogic_matrix;

package ram_generics is
    generic (size, addr_size: positive);
    subtype Address is natural range 0 to 2**(addr_size-2) - 1;
    subtype word is std_ulogic_vector(size - 1 downto 0);
    subtype Contents is std_ulogic_matrix(Address)(word'range);
end package ram_generics;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    generic(
        package types is new work.ram_generics generic map (<>);
        clk_edge: std_ulogic := '1';
        initial_content: types.Contents := (others => (others => '0'))
    );
    port(
        clk, w, r, se: in std_ulogic;
        bw: in unsigned(1 downto 0);
        addr: in unsigned(types.addr_size - 1 downto 0);
        data: inout types.word
    );
    use types.size;
end;

architecture behaviour of RAM is
    signal w_enable: std_ulogic_vector(3 downto 0);
    signal ram_in, ram_out, word_out: data'subtype;
    constant byte_size: positive := types.size / 4;
begin
    bram: entity work.BlockRAM
        generic map (byte_size, types.addr_size - 2, 4, clk_edge, initial_content)
        port map (
            clk, w and w_enable,
            addr(addr'high downto 2),
            ram_in, ram_out
        );

    selector: entity work.ByteSelector generic map (byte_size, 2) port map (
        ram_out, data,
        ram_in, word_out,
        addr(1 downto 0), bw,
        w_enable,
        se
    );

    data <= word_out when not w and r else (others => 'Z');
end;
