library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.std_ulogic_matrix;

entity OpcodeDecoder is
    generic(
        size, opcode_size: positive;
        patterns: std_ulogic_matrix(open)(size - 1 downto 0);
    );
    port(
        instruction: in std_ulogic_vector(size - 1 downto 0);
        opcode: out unsigned(opcode_size - 1 downto 0);
        instruction_exception: out std_ulogic
    );
end;

architecture behaviour of OpcodeDecoder is
begin
    process(all)
    begin
        instruction_exception <= '1';
        opcode <= (others => 'X');
        for i in patterns'range loop
            if instruction ?= patterns(i) then
                opcode <= to_unsigned(i, opcode_size);
                instruction_exception <= '0';
                exit;
            end if;
        end loop;
    end process;
end;
