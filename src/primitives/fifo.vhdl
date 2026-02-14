library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FIFO is
    generic(
        size, capacity: positive;
        almost_full_level, almost_empty_level: natural range 0 to capacity;
    );
    port(
        -- Control signals
        clk, r, w: in std_ulogic;
        -- Data I/O
        w_data: in std_ulogic_vector(size - 1 downto 0);
        r_data: out std_ulogic_vector(size - 1 downto 0);
        -- Status signals
        full, empty, almost_full, almost_empty: buffer std_ulogic;
    );
end;

architecture behaviour of FIFO is
    type FIFO_DATA is array (0 to capacity - 1) of std_ulogic_vector(size - 1 downto 0);
    signal contents: FIFO_DATA := (others => (others => '0'));

    signal w_idx, r_idx: natural range 0 to capacity - 1 := 0;
    signal count: natural range 0 to capacity := 0;

    pure function inc_mod(x: natural) return natural is
    begin
        if x < capacity - 1 then
            return x + 1;
        else
            return 0;
        end if;
    end function;
begin
    control: process(clk)
    begin
        if rising_edge(clk) then
            if w and not r and not full then
                count <= count + 1;
            elsif r and not w and not empty then
                count <= count - 1;
            end if;

            if w and not (full and not r) then
                w_idx <= inc_mod(w_idx);
            end if;
            if r and not empty then
                r_idx <= inc_mod(r_idx);
            end if;

            if w and not (full and not r) then
                contents(w_idx) <= w_data;
            end if;
        end if;
    end process;

    r_data <= contents(r_idx) when not empty else (others => '0');

    full <= '1' when count = capacity else '0';
    empty <= '1' when count = 0 else '0';
    almost_full <= '1' when count > almost_full_level else '0';
    almost_empty <= '1' when count < almost_empty_level else '0';
end;
