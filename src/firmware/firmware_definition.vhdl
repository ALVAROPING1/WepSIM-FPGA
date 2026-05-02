library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.std_ulogic_matrix;

package firmware_types is
    type microinstruction is record
        cond: unsigned(3 downto 0);
        b, a0, mr: std_ulogic;
        sel_a, sel_b, sel_c: unsigned(4 downto 0);
        lc: std_ulogic;
        t: std_ulogic_vector(1 to 14);
        c: std_ulogic_vector(0 to 7);
        ma, m1, m2, m7, mh: std_ulogic;
        mb: unsigned(1 downto 0);
        opcode: std_ulogic_vector(4 downto 0);
        se: std_ulogic;
        ir_size, ir_offset: unsigned(4 downto 0);
        bw: unsigned(1 downto 0);
        w, r, iow, ior, inta: std_ulogic;
        selp: std_ulogic_vector(1 downto 0);
        interrupts, user: std_ulogic;
        ex_code: std_ulogic_vector(3 downto 0);
        pause: std_ulogic;
    end record;

    type ControlMemoryROM is array (natural range 0 to 2**12 - 1) of microinstruction;

    subtype OpcodePatterns is std_ulogic_matrix(open)(31 downto 0);
    subtype OpcodeTable is std_ulogic_matrix(open)(11 downto 0);
end package;
