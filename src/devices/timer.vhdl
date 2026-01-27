library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Timer is
    generic(size: positive);
    port(
        clk, iow: in std_ulogic;
        addr: in unsigned(15 downto 0);
        data: in std_ulogic_vector(size - 1 downto 0);
        inta: in std_ulogic;
        int: out std_ulogic;
        intv: out std_ulogic_vector(size - 1 downto 0);
    );
end;

architecture behaviour of Timer is
    signal id, length: std_ulogic_vector(data'range) := (others => '0');
    signal update_id, update_length, pending: std_ulogic := '0';
    signal counter: unsigned(data'range) := (others => '0');
begin
    id_reg:     entity work.Reg generic map (size) port map (clk, update_id, data, id);
    length_reg: entity work.Reg generic map (size) port map (clk, update_length, data, length);

    update_id <=     '1' when iow = '1' and addr = x"1104" else '0';
    update_length <= '1' when iow = '1' and addr = x"1108" else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            if update_length then
                pending <= '0';
                counter <= (others => '0');
            elsif unsigned(length) /= 0 then
                if not pending then
                    if counter = unsigned(length) - 1 then
                        counter <= (others => '0');
                        pending <= '1';
                    else
                        counter <= counter + 1;
                    end if;
                elsif inta then
                    pending <= '0';
                end if;
            end if;
        end if;
    end process;

    int <= pending;
    intv <= id when pending and inta else (others => 'Z');
end;
