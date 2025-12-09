library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Slicer is
    generic(offset_size, out_size: positive);
    port(
        data_in: in std_ulogic_vector(2**offset_size - 1 downto 0);
        data_out: out std_ulogic_vector(out_size - 1 downto 0);
        offset: in unsigned(offset_size - 1 downto 0)
    );
end;

architecture behaviour of Slicer is
begin
    assert 2**offset_size > out_size report "Input data must be bigger than output data" severity error;

    process(all)
        variable v_offset, v_size: natural;
        variable high: natural;
    begin
        v_offset := to_integer(offset);
        high := minimum(v_offset + out_size - 1, data_in'high);
        v_size := high - v_offset + 1;
        data_out <= (others => '0');
        data_out(v_size - 1 downto 0) <= data_in(high downto v_offset);
    end process;
end;
