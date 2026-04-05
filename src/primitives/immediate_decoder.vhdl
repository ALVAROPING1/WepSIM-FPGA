library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ImmediateDecoder is
    generic (
        offset_size: positive;
        pure function mapper(id: natural; data: std_ulogic_vector)
        return std_ulogic_vector
    );
    port(
        data_in: in std_ulogic_vector(2**offset_size - 1 downto 0);
        data_out: out std_ulogic_vector(2**offset_size - 1 downto 0);
        offset, size: in unsigned(offset_size - 1 downto 0);
        sign_extend: in std_logic
    );
end;

architecture behaviour of ImmediateDecoder is
begin
    process(all)
        variable v_offset, v_size: natural;
        variable high: integer;
    begin
        data_out <= (others => '0');
        v_offset := to_integer(offset);
        if size > 0 then
            v_size := to_integer(size);
            high := minimum(v_offset + v_size - 1, data_in'high);
            v_size := high - v_offset + 1;
            data_out(v_size - 1 downto 0) <= data_in(high downto v_offset);
            data_out(data_out'high downto v_size) <= (others => data_in(high)) when sign_extend else (others => '0');
        else
            data_out <= mapper(v_offset, data_in);
        end if;
    end process;
end;
