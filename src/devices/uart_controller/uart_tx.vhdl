library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UARTTX is
    port(
        -- CPU control signals
        clk, clk_e, iow: in std_ulogic;
        -- UART pins
        tx: out std_ulogic;
        cts: in std_ulogic;
        -- CPU input/output
        data: in std_ulogic_vector(7 downto 0);
        -- CPU status signals
        accept_in, accepted: out std_ulogic
    );
end;

architecture behaviour of UARTTX is
    signal sending, n_sending: std_ulogic := '0';
    signal count: integer range -1 to 8 := 0;
    signal tick: natural range 0 to 7 := 0;
begin
    control: process(all)
    begin
        if sending then
            accept_in <= '0';
            n_sending <= '1' when count < 8 else '0';
            tx <= '0'         when count = -1 else
                  data(count) when count < 8  else
                  '1';
            accepted <= '1' when count = 8 else '0';
        else
            accept_in <= not cts;
            n_sending <= iow and not cts;
            tx <= '1';
            accepted <= '0';
        end if;
    end process;

    update: process(clk)
    begin
        if rising_edge(clk) then
            if clk_e then
                if tick = tick'high or sending = '0' then
                    tick <= 0;
                    sending <= n_sending;
                    count <= count + 1 when sending and n_sending else -1;
                else
                    tick <= tick + 1;
                end if;
            end if;
        end if;
    end process;
end;
