library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ByteSelector is
    generic(
        byte_size, log_n_bytes: positive;
    );
    port(
        bytes_in, word_in: in std_ulogic_vector(byte_size * 2**log_n_bytes - 1 downto 0);
        bytes_out, word_out: out bytes_in'subtype;
        addr, bw: in unsigned(log_n_bytes - 1 downto 0);
        byte_enable: out std_ulogic_vector(2**log_n_bytes - 1 downto 0);
        sign_extend: in std_ulogic;
    );
end;

architecture behaviour of ByteSelector is
    constant n_bytes: positive := 2**log_n_bytes;

    signal bits_off, high: natural range bytes_in'range := 0;
begin
    range_calc: process(all)
        variable v_addr: unsigned(addr'high + 1 downto 0);
        variable size: positive range 1 to n_bytes;
        variable offset: natural range 0 to n_bytes - 1;
    begin
        v_addr := '0' & addr;
        -- These values should never be used, since 2**(bw'high+1) should be
        -- bigger than any possible value of bw, but we need to provide a
        -- default value in order for the synthetizer to not infer a latch
        size := size'high;
        offset := 0;
        for i in 0 to bw'high + 1 loop
            if bw < 2**i then
                size := 2**i;
                offset := to_integer(v_addr(v_addr'high downto i)) * size;
                exit;
            end if;
        end loop;
        high <= size * byte_size - 1;
        bits_off <= offset * byte_size;
        byte_enable <= (others => '0');
        byte_enable(offset + size - 1 downto offset) <= (others => '1');
    end process;

    read: process(all)
    begin
        word_out <= (others => '0');
        word_out(high downto 0) <= bytes_in(high + bits_off downto bits_off);
        if sign_extend = '1' and high < word_out'high then
            word_out(word_out'high downto high + 1)
                <= (others => bytes_in(high + bits_off));
        end if;
    end process;

    write: process(all)
    begin
        bytes_out <= (others => '0');
        bytes_out(high + bits_off downto bits_off) <= word_in(high downto 0);
    end process;
end;
