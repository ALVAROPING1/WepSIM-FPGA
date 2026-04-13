library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ByteSelector is
    generic(
        byte_size, log_n_bytes: positive;
        little_endian: boolean := true;
    );
    port(
        bytes_in, word_in: in std_ulogic_vector(byte_size * 2**log_n_bytes - 1 downto 0);
        bytes_out, word_out: out bytes_in'subtype;
        addr, bw: in unsigned(log_n_bytes - 1 downto 0);
        sign_extend: in std_ulogic;
        byte_enable: out std_ulogic_vector(2**log_n_bytes - 1 downto 0);
    );
end;

architecture behaviour of ByteSelector is
    constant n_bytes: positive := 2**log_n_bytes;

    signal bits_off: natural range bytes_in'range := 0;
    signal high: natural range bytes_in'range := byte_size - 1;
    signal size: positive range 1 to n_bytes;

    impure function reorder(bytes: std_ulogic_vector) return std_ulogic_vector is
        variable buf: bytes'subtype := bytes;
    begin
        if not little_endian then
            for i in 0 to size - 1 loop
                buf((size - i) * byte_size - 1 downto (size - i - 1) * byte_size)
                    := bytes((i + 1) * byte_size - 1 downto i * byte_size);
            end loop;
        end if;
        return buf;
    end function;
begin
    range_calc: process(all)
        variable v_addr: unsigned(addr'high + 1 downto 0);
        variable v_size: size'subtype;
        variable offset: natural range 0 to n_bytes - 1;
    begin
        v_addr := '0' & addr;
        -- These values should never be used, since 2**(bw'high+1) should be
        -- bigger than any possible value of bw, but we need to provide a
        -- default value in order for the synthetizer to not infer a latch
        v_size := v_size'high;
        offset := 0;
        for i in 0 to bw'high + 1 loop
            if bw < 2**i then
                v_size := 2**i;
                offset := to_integer(v_addr(v_addr'high downto i)) * v_size;
                exit;
            end if;
        end loop;
        size <= v_size;
        high <= v_size * byte_size - 1;
        bits_off <= offset * byte_size;
        byte_enable <= (others => '0');
        byte_enable(offset + v_size - 1 downto offset) <= (others => '1');
    end process;

    read: process(all)
        variable buf: word_out'subtype;
    begin
        buf := (others => '0');
        buf(high downto 0) := bytes_in(high + bits_off downto bits_off);
        buf := reorder(buf);
        if sign_extend = '1' and high < word_out'high then
            buf(word_out'high downto high + 1) := (others => buf(high));
        end if;
        word_out <= buf;
    end process;

    write: process(all)
    begin
        bytes_out <= (others => '0');
        bytes_out(high + bits_off downto bits_off) <= reorder(word_in)(high downto 0);
    end process;
end;
