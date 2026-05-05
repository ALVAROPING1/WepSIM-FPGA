library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package cpu_pkg is
    type control_signals is record
        lc: std_ulogic;
        ra, rb, rc: unsigned(4 downto 0);
        t: std_ulogic_vector(1 to 14);
        c: std_ulogic_vector(0 to 7);
        ma, m1, m2, m7, mh: std_ulogic;
        mb: unsigned(1 downto 0);
        opcode: std_ulogic_vector(4 downto 0);
        se: std_ulogic;
        ir_size, ir_offset: unsigned(4 downto 0);
        selp: std_ulogic_vector(1 downto 0);
        interrupts, user: std_ulogic;
        ex_code: std_ulogic_vector(3 downto 0);
        instruction_finish: std_ulogic;
    end record;

    type control_bus_signals is record
        w, r, iow, ior, se, inta, running: std_ulogic;
        bw: unsigned(1 downto 0);
    end record;
end package cpu_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_pkg.all;

entity ControlUnit is
    generic (size: positive);
    port(
        clk: in std_ulogic;
        step_instruction, continue: in std_ulogic;
        int, io_rdy, m_rdy: in std_ulogic;
        instruction, state: in std_ulogic_vector(size - 1 downto 0);
        control: out control_signals;
        control_bus: out control_bus_signals;
    );
end;

architecture behaviour of ControlUnit is
    use work.firmware;
    signal addr, next_addr, maddr, opcode_addr: std_ulogic_vector(11 downto 0);
    signal mux_c_out, mux_b_out, inst_exception, step, running, fetch: std_ulogic;
    signal inst: work.firmware_types.microinstruction;
    signal sel_ra_imm, sel_rb_imm, sel_rc_imm: std_ulogic_vector(4 downto 0);
    signal ra, rb, rc: std_ulogic_vector(4 downto 0);
begin
    inst <= firmware.control_memory(to_integer(unsigned(addr)));
    control.lc <= inst.lc;
    control.t <= inst.t;
    control.c <= inst.c;
    control.ma <= inst.ma;
    control.m1 <= inst.m1;
    control.m2 <= inst.m2;
    control.m7 <= inst.m7;
    control.mh <= inst.mh;
    control.mb <= inst.mb;
    control.opcode <= inst.opcode;
    control.se <= inst.se;
    control.ir_size <= inst.ir_size;
    control.ir_offset <= inst.ir_offset;
    control.selp <= inst.selp;
    control.interrupts <= inst.interrupts;
    control.user <= inst.user;
    control.ex_code <= inst.ex_code;

    fetch <= '1' when unsigned(addr) = 0 else '0';
    inst_end: entity work.EdgeDetector port map (clk, fetch, control.instruction_finish);

    control_bus.ior <= inst.ior;
    control_bus.iow <= inst.iow;
    control_bus.inta <= inst.inta;
    control_bus.w <= inst.w;
    control_bus.r <= inst.r;
    control_bus.se <= inst.se;
    control_bus.bw <= inst.bw;
    control_bus.running <= running;

    maddr <= std_ulogic_vector(inst.sel_a & inst.sel_b & inst.sel_c(4 downto 3));

    decoder: entity work.OpcodeDecoder
        generic map (size, opcode_addr'high + 1, firmware.patterns, firmware.addrs)
        port map(instruction, opcode_addr, inst_exception);

    addr_reg: entity work.Reg
        generic map (12, initial => firmware.cu_start)
        port map (clk, running, next_addr, addr);

    step_edge_detector: entity work.EdgeDetector port map (clk, step_instruction, step);
    running <= '1' when step = '1' or (inst.pause = '0' and (unsigned(addr) /= 0 or continue = '1')) else '0';

    mux_a: entity work.Multiplexer generic map (12, 2) port map ((std_ulogic_vector(unsigned(addr) + 1), opcode_addr, maddr, x"000"), next_addr, mux_b_out & inst.a0);
    mux_b: entity work.Multiplexer generic map (1, 1) port map (((0 => mux_c_out), (0 => not mux_c_out)), data_out(0) => mux_b_out, sel(0) => inst.b);
    mux_c: entity work.Multiplexer generic map (1, 4) port map (
        (
            (0 => '0'),
            (0 => int),
            (0 => io_rdy),
            (0 => m_rdy),
            (0 => state(0)),
            (0 => state(1)),
            (0 => state(28)),
            (0 => state(29)),
            (0 => state(30)),
            (0 => state(31)),
            (0 => inst_exception),
            others => "0"
        ),
        data_out(0) => mux_c_out,
        sel => inst.cond
    );

    sel_ra: entity work.Slicer generic map (5, 5) port map (instruction, sel_ra_imm, inst.sel_a);
    sel_rb: entity work.Slicer generic map (5, 5) port map (instruction, sel_rb_imm, inst.sel_b);
    sel_rc: entity work.Slicer generic map (5, 5) port map (instruction, sel_rc_imm, inst.sel_c);

    mux_ra: entity work.Multiplexer generic map (5, 1) port map ((sel_ra_imm, std_ulogic_vector(inst.sel_a)), ra, sel(0) => inst.mr);
    mux_rb: entity work.Multiplexer generic map (5, 1) port map ((sel_rb_imm, std_ulogic_vector(inst.sel_b)), rb, sel(0) => inst.mr);
    mux_rc: entity work.Multiplexer generic map (5, 1) port map ((sel_rc_imm, std_ulogic_vector(inst.sel_c)), rc, sel(0) => inst.mr);
    control.ra <= unsigned(ra);
    control.rb <= unsigned(rb);
    control.rc <= unsigned(rc);
end;
