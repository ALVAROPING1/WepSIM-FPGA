library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UARTRX is
    port(
        -- CPU control signals
        clk, clk_e, ior: in std_ulogic;
        -- UART pins
        rx: in std_ulogic;
        rts: out std_ulogic;
        -- CPU input/output
        data: out std_ulogic_vector(7 downto 0);
        -- CPU status signals
        data_valid: out std_ulogic
    );
end;

architecture behaviour of UARTRX is
    signal receiving, rx_filtered: std_ulogic := '0';
    signal count: natural range 0 to 8 := 0;
    signal data_buf: std_ulogic_vector(7 downto 0) := (others => '0');
    signal tick: natural range 0 to 7 := 0;
    signal state: unsigned(1 downto 0) := "00";
begin
    filter: process(clk)
    begin
        if rising_edge(clk) and clk_e = '1' then
            state <= state - 1 when rx = '0' and state /= "00" else
                     state + 1 when rx = '1' and state /= "11" else
                     state;
        end if;
    end process;
    rx_filtered <= state(state'high);

    receive: process(clk)
        variable start, idle: boolean;
        constant midpoint: positive := (tick'high + state'high + 2) / 2;
    begin
        if rising_edge(clk) and clk_e = '1' then
            start := receiving = '0' and rx_filtered = '0'; -- Check for packet start
            idle := receiving = '0' and rx_filtered = '1'; -- Check for idle
            -- Re-synchronize clock half a transmission bit after we detect the
            -- start bit. This allows to sample data bits on the middle of their
            -- transmission to minimize errors
            if tick = tick'high or (start and tick = midpoint) or idle then
                tick <= 0;
                if receiving then
                    if count < 8 then
                        data_buf <= rx_filtered & data_buf(7 downto 1);
                        count <= count + 1;
                    elsif rx_filtered then
                        receiving <= '0';
                    end if;
                else
                    receiving <= not rx_filtered;
                    count <= 0;
                    data_buf <= (others => '0');
                end if;
            else
                tick <= tick + 1;
            end if;
        end if;
    end process;
    rts <= not ior;
    data <= data_buf;
    data_valid <= '1' when receiving = '1' and count = 8 else '0';
end;
