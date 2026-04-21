library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.std_ulogic_matrix;

entity OpcodeDecoder is
    generic(
        instruction_size, addr_size: positive;
        patterns: std_ulogic_matrix(open)(instruction_size - 1 downto 0);
        addr_table: std_ulogic_matrix(patterns'range)(addr_size - 1 downto 0);
    );
    port(
        instruction: in std_ulogic_vector(instruction_size - 1 downto 0);
        addr: out std_ulogic_vector(addr_size - 1 downto 0);
        instruction_exception: out std_ulogic
    );
end;

architecture behaviour of OpcodeDecoder is
begin
    process(all)
    begin
        instruction_exception <= '1';
        addr <= (others => 'X');
        for i in patterns'range loop
            if instruction ?= patterns(i) then
                addr <= addr_table(i);
                instruction_exception <= '0';
                exit;
            end if;
        end loop;
    end process;
end;
