library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is
    generic(size: positive);
    port(
        a, b: in std_ulogic_vector(size - 1 downto 0);
        opcode: in std_ulogic_vector(4 downto 0);
        result: out std_ulogic_vector(size - 1 downto 0);
        carry, overflow, negative, zero: out std_ulogic
    );
end;

architecture behaviour of ALU is
    signal adder_res: signed(result'range);
    signal adder_sub, adder_overflow, adder_carry, signed_arith: std_ulogic;
    signal res: result'subtype;

    signal mult_res: signed(size * 2 - 1 downto 0);
    signal mult_signed_a, mult_signed_b, mult_overflow: std_ulogic;
begin
    adder: entity work.Adder
        generic map (size)
        port map (
            a, b, adder_res,
            adder_sub, signed_arith,
            adder_overflow, adder_carry
        );

    multiplier: entity work.Multiplier
        generic map (size)
        port map (a, b, mult_signed_a, mult_signed_b, mult_res, mult_overflow);

    adder_sub <= '1' when opcode = "01011" or opcode = "10111" else '0';
    signed_arith <= '1' when opcode = "01010" or opcode = "01011" else '0';

    mult_signed_a <= '1' when opcode = "11010" or opcode = "11100" else '0';
    mult_signed_b <= '1' when opcode = "11010" else '0';

    alu: process(all)
        variable int_b: natural;
    begin
        int_b := to_integer(unsigned(b) mod size);
        overflow <= '0';
        carry <= '0';
        case opcode is
            when "00000" => res <= (others => '0');
            when "00001" => res <= a and b;
            when "00010" => res <= a or b;
            when "00011" => res <= not a;
            when "00100" => res <= a xor b;
            when "00101" => res <= a srl int_b;
            when "00110" => res <= std_ulogic_vector(signed(a) sra int_b);
            when "00111" => res <= a sll int_b;
            when "01000" => res <= a ror int_b;
            when "01001" => res <= a rol int_b;
            when "01010" | "01011" | "10110" | "10111" =>
                res <= std_ulogic_vector(adder_res);
                overflow <= adder_overflow;
                carry <= adder_carry;
            when "01100" =>
                res <= std_ulogic_vector(mult_res(res'range));
                overflow <= mult_overflow;
            when "11010" | "11011" | "11100" =>
                res <= std_ulogic_vector(mult_res(mult_res'high downto size));
            when others =>
                res <= (others => 'X');
                overflow <= 'X';
                carry <= 'X';
        end case;
    end process;

    result <= res;

    negative <= '1' when signed(res) < 0 else '0';
    zero <= '1' when signed(res) = 0 else '0';
end;
