library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    generic(size, addr_size: positive; clk_edge: std_ulogic := '1');
    port(
        clk, w, r, se: in std_ulogic;
        bw: in std_ulogic_vector(1 downto 0);
        addr: in unsigned(addr_size - 1 downto 0);
        data: inout std_ulogic_vector(size - 1 downto 0)
    );
end;

architecture behaviour of RAM is
    subtype Address is natural range 0 to 2**(addr_size-2) - 1;
    type State is array (Address) of std_ulogic_vector(data'range);
    signal contents: State := (others => (others => '0'));

    signal pending_write: std_ulogic := '0';
    signal read_data, masked_data, mask: std_ulogic_vector(data'range);
    signal bits, prev_bits: positive range 1 to size := size;
    signal offset, prev_offset: natural range 0 to size-1 := 0;
    signal word_addr, prev_word_addr: Address := 0;
    signal res: std_ulogic_vector(data'range);
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
