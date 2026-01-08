library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ram_generics is
    generic (size, addr_size: positive);
    subtype Address is natural range 0 to 2**(addr_size-2) - 1;
    subtype word is std_ulogic_vector(size - 1 downto 0);
    type State is array (Address) of word;
end package ram_generics;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    generic(
        package types is new work.ram_generics generic map (<>);
        clk_edge: std_ulogic := '1';
        initial_content: types.State := (others => (others => '0'))
    );
    port(
        clk, w, r, se: in std_ulogic;
        bw: in std_ulogic_vector(1 downto 0);
        addr: in unsigned(types.addr_size - 1 downto 0);
        data: inout types.word
    );
    use types.size;
end;

architecture behaviour of RAM is
    signal contents: types.State := initial_content;

    signal pending_write: std_ulogic := '0';
    signal read_data, masked_data, mask, res: types.word;
    signal bits, prev_bits: positive range 1 to size := size;
    signal offset, prev_offset: natural range 0 to size-1 := 0;
    signal word_addr, prev_word_addr: types.Address := 0;
begin
    -- Calculate section to read/write
    with bw select
        bits <= size/4 when "00",
                size/2 when "01",
                size   when others;
    with bw select
        offset <= to_integer(addr(1 downto 0)) * size/4 when "00",
                  to_integer(addr(1 downto 1)) * size/2 when "01",
                  0                                     when others;
    word_addr <= to_integer(addr(addr'high downto 2));

    -- Synchronous read/write
    process(all)
    begin
        masked_data <= read_data;
        masked_data(prev_offset + prev_bits - 1 downto prev_offset) <= mask(prev_bits - 1 downto 0);
    end process;

    process(clk)
    begin
        if clk'event and clk = clk_edge then
            read_data <= contents(word_addr);
            if pending_write then
                contents(prev_word_addr) <= masked_data;
            end if;

            mask <= data;
            pending_write <= w;
            prev_offset <= offset;
            prev_bits <= bits;
            prev_word_addr <= word_addr;
        end if;
    end process;

    -- Post-process reads
    process(read_data, offset, bits, se)
    begin
        res <= (others => '0');
        res(bits - 1 downto 0) <= read_data(offset + bits - 1 downto offset);
        if bits - 1 < res'high then
            res(res'high downto bits)
                <= (others => read_data(offset + bits - 1)) when se else (others => '0');
        end if;
    end process;
    data <= res when not w and r else (others => 'Z');
end;
