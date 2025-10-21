package bcd is
    subtype digit is natural range 0 to 9;
    type bcd_vector is array (natural range <>) of digit;
end;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.bcd.bcd_vector;

entity BCDDecoder is
    generic(
        input_size, output_size: positive
    );
    port(
        data_in: in unsigned(input_size - 1 downto 0);
        data_out: out bcd_vector(output_size - 1 downto 0)
    );
end;

architecture behaviour of BCDDecoder is
    constant BUF_SIZE: positive := input_size + 4 * output_size;
begin
    process(data_in)
        variable buf: unsigned(BUF_SIZE - 1 downto 0);
        variable offset: positive;
    begin
        buf := (others => '0');
        buf(input_size - 1 downto 0) := data_in;
        for i in 0 to input_size - 1 loop
            for x in 0 to output_size - 1 loop
                offset := x * 4 + input_size;
                if buf(offset + 3 downto offset) > 4 then
                    buf(offset + 3 downto offset) := buf(offset + 3 downto offset) + 3;
                end if;
            end loop;
            buf := buf(buf'high - 1 downto 0) & '0';
        end loop;

        for i in 0 to output_size - 1 loop
            offset := i * 4 + input_size;
            data_out(i) <= to_integer(buf(offset + 3 downto offset));
        end loop;
    end process;

    -- rtl_synthesis off
    process(data_in)
    begin
        for i in 0 to input_size - 1 loop
            assert not is_x(data_in(i)) report "Invalid metavalue in input" severity failure;
        end loop;
    end process;
    -- rtl_synthesis on
end;
