library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_pkg.control_bus_signals;
use work.cpu_pkg.control_signals;
use work.utils.std_ulogic_matrix;

entity Cpu is
    port (
        clk, step_instruction, continue: in std_ulogic;
        address_bus: out std_ulogic_vector(31 downto 0);
        data_bus: inout std_logic_vector(31 downto 0);
        control_bus: out control_bus_signals;
        int, m_rdy: in std_ulogic;
        -- io_rdy: in std_ulogic;
        debug_reg: in unsigned(4 downto 0);
        debug_sel: in std_ulogic_vector(1 downto 0);
        debug_data: out std_ulogic_vector(31 downto 0);
    );
end;

architecture behaviour of Cpu is
    constant size: positive := 32;
    subtype word is std_ulogic_vector(size - 1 downto 0);
    constant kernel_start: word := x"00000800";

    signal internal_bus: std_logic_vector(size - 1 downto 0);
    type word_vector is array (natural range <>) of word;
    signal a, b, c, alu_a, alu_b, res, mar, mbr, pc, next_pc, ir, ir_segment, sr, state, next_state, memory, cycles, hpc, instructions, excode: word;
    signal rt: word_vector(1 to 3);
    signal alu_state: std_ulogic_vector(3 downto 0);
    signal c_signals: control_signals;
    signal excode_sign: std_ulogic;
begin
    control_unit: entity work.ControlUnit generic map (size) port map (
        clk, step_instruction, continue,
        int, '1', m_rdy,
        ir, sr,
        c_signals, control_bus
    );

    register_file: entity work.RegisterFile
        generic map (size, addr_size => 5, read_outputs => 3)
        port map (
            clk, c_signals.lc,
            c_signals.rc, internal_bus,
            (c_signals.ra, c_signals.rb, debug_reg),
            r_data(0) => a, r_data(1) => b, r_data(2) => c
        );

    alu: entity work.ALU
        generic map (size)
        port map(
            alu_a, alu_b, c_signals.cop, res,
            carry => alu_state(3), overflow => alu_state(2),
            negative => alu_state(1), zero => alu_state(0)
        );

    mar_reg: entity work.Reg generic map (size) port map (clk, c_signals.c(0), internal_bus, mar);
    mbr_reg: entity work.Reg generic map (size) port map (clk, c_signals.c(1), memory, mbr);
    pc_reg:  entity work.Reg generic map (size, initial => kernel_start) port map (clk, c_signals.c(2), next_pc, pc);
    ir_reg:  entity work.Reg generic map (size) port map (clk, c_signals.c(3), internal_bus, ir);
    rt1:     entity work.Reg generic map (size) port map (clk, c_signals.c(4), internal_bus, rt(1));
    rt2:     entity work.Reg generic map (size) port map (clk, c_signals.c(5), internal_bus, rt(2));
    rt3:     entity work.Reg generic map (size) port map (clk, c_signals.c(6), res, rt(3));
    sr_reg:  entity work.Reg generic map (size) port map (clk, c_signals.c(7), state, sr);
    clk_reg: entity work.Reg generic map (size) port map (clk, '1', word(unsigned(cycles) + 1), cycles);
    ins_reg: entity work.Reg generic map (size) port map (clk, c_signals.instruction_finish, word(unsigned(instructions) + 1), instructions);

    ta:      entity work.TriState generic map (size) port map (mar, address_bus, c_signals.ta);
    td:      entity work.TriState generic map (size) port map (mbr, data_bus, c_signals.td);
    t1:      entity work.TriState generic map (size) port map (mbr, internal_bus, c_signals.t(1));
    t2:      entity work.TriState generic map (size) port map (pc, internal_bus, c_signals.t(2));
    t3:      entity work.TriState generic map (size) port map (ir_segment, internal_bus, c_signals.t(3));
    t4:      entity work.TriState generic map (size) port map (rt(1), internal_bus, c_signals.t(4));
    t5:      entity work.TriState generic map (size) port map (rt(2), internal_bus, c_signals.t(5));
    t6:      entity work.TriState generic map (size) port map (res, internal_bus, c_signals.t(6));
    t7:      entity work.TriState generic map (size) port map (rt(3), internal_bus, c_signals.t(7));
    t8:      entity work.TriState generic map (size) port map (sr, internal_bus, c_signals.t(8));
    t9:      entity work.TriState generic map (size) port map (a, internal_bus, c_signals.t(9));
    t10:     entity work.TriState generic map (size) port map (b, internal_bus, c_signals.t(10));
    t11:     entity work.TriState generic map (size) port map (excode, internal_bus, c_signals.t(11));
    t12:     entity work.TriState generic map (size) port map (hpc, internal_bus, c_signals.t(12));

    mux_a:   entity work.Multiplexer generic map (size, 1) port map ((a, rt(1)), alu_a, sel(0) => c_signals.ma);
    mux_b:   entity work.Multiplexer generic map (size, 2) port map ((b, rt(2), "00000000000000000000000000000100",  "00000000000000000000000000000001"), alu_b, c_signals.mb);
    mux1:    entity work.Multiplexer generic map (size, 1) port map ((internal_bus, data_bus), memory, sel(0) => c_signals.m1);
    mux2:    entity work.Multiplexer generic map (size, 1) port map ((internal_bus, word(unsigned(pc) + 4)), next_pc, sel(0) => c_signals.m2);
    mux7:    entity work.Multiplexer generic map (size, 1) port map ((internal_bus, next_state), state, sel(0) => c_signals.m7);
    mux_mh:  entity work.Multiplexer generic map (size, 1) port map ((cycles, instructions), hpc, sel(0) => c_signals.mh);

    excode_sign <= c_signals.excode(c_signals.excode'high) when c_signals.se else '0';
    excode <= (c_signals.excode'range => c_signals.excode, others => excode_sign);

    ir_select: entity work.ImmediateDecoder
        generic map (5, work.firmware.immediate_decoder)
        port map (ir, ir_segment, c_signals.offset, c_signals.size, c_signals.se);

    state_mask: process(all)
    begin
        next_state <= sr;
        case c_signals.selp is
            when "00" => null;
            when "01" => next_state(0) <= c_signals.user;
            when "10" => next_state(1) <= c_signals.interrupts;
            when "11" => next_state(31 downto 28) <= alu_state;
            when others => next_state <= (others => 'X');
        end case;
    end process;

    with debug_sel select?
        debug_data <= c  when "00",
                      pc when "01",
                      ir when "1-",
                      (others => '0') when others;
end;
