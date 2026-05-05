from typing import Final, TypeAlias
import re

Value: TypeAlias = bool | str
MicroInstruction: TypeAlias = list[str | tuple[str, Value]]

MEMORY: Final[list[str | int | MicroInstruction]] = [
    ["mr", ("sel_c", "00000"), ("ex_code", "0000"), "t11", "lc"], # x0 <- 0
    # Check async interrupts
    [("cond", "0001"), ("sel_a", "00000"), ("sel_b", "00001"), ("sel_c", "11000")], # jump to mrti
    # Fetch
    ["t2", "c0"],
    ["t13"],
    ["r", "m1", "c1", ("bw", "11")],
    ["m2", "c2", "t1", "c3"],
    ["a0", ("b", False)],
    # mrti
    ["inta", "m1", "c1"],
    ["t1", "c4"],
    # csw_rt1
    ["mr", ("sel_a", "00010"), ("sel_c", "00010"), ("mb", "10"), ("opcode", "01011"), "t6", "lc", "c0"],
    ["t2", "c1"],
    ["w", "t13", "t14", ("bw", "11")],

    ["mr", ("sel_a", "00010"), ("sel_c", "00010"), ("mb", "10"), ("opcode", "01011"), "t6", "lc", "c0"],
    ["t8", "c1"],
    ["w", "t13", "t14", ("bw", "11")],

    ["ma", ("mb", "10"), ("opcode", "01100"), "t6", "c0"],

    ["t13"],
    ["t13", "r", "m1", "c1", ("bw", "11")],

    [("cond", "0000"), "b", ("sel_a", "00000"), ("sel_b", "00000"), ("sel_c", "10000"), "c2", "t1", ("selp", "01"), ("user", False), "m7", "c7"], # jump to fetch

    2048,
    # RV32I
    "lui",
    ["b", "a0", ("sel_c", "00111"), ("ir_size", "00000"), ("ir_offset", "00100"), "t3", "lc"],
    "auipc",
    ["t2", "c4"],
    [("opcode", "01011"), "ma", ("mb", "10"), "t6", "c4"],
    [("ir_size", "00000"), ("ir_offset", "00100"), "t3", "c5"],
    ["b", "a0", ("sel_c", "00111"), ("opcode", "01010"), "ma", ("mb", "01"), "t6", "lc"],
    "jal",
    [("sel_c", "00111"), "t2", "lc"],
    ["t2", "c4"],
    [("opcode", "01011"), "ma", ("mb", "10"), "t6", "c4"],
    [("ir_size", "00000"), ("ir_offset", "00101"), "t3", "c5"],
    ["b", "a0", ("opcode", "01010"), "ma", ("mb", "01"), "t6", "c2"],
    "jalr",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    [("sel_a", "01111"), ("opcode", "01010"), ("mb", "01"), "t6", "c4"],
    [("opcode", "00101"), "ma", ("mb", "11"), "t6", "c4"],
    [("sel_c", "00111"), ("opcode", "00111"), "ma", ("mb", "11"), "c6", "t2", "lc"],
    ["b", "a0", "t7", "c2"],
    "beq",
    [("sel_a", "01111"), ("sel_b", "10100"), ("opcode", "01011"), ("selp", "11"), "m7", "c7", "t2", "c4"],
    [("cond", "0110"), "b", ("sel_a", "00000"), ("sel_b", "00000"), ("sel_c", "00000"), ("opcode", "01011"), "ma", ("mb", "10"), "t6", "c4"],
    [("ir_size", "00000"), ("ir_offset", "00011"), "t3", "c5"],
    ["b", "a0", "ma", ("mb", "01"), ("opcode", "01010"), "t6", "c2"],
    "bne",
    [("sel_a", "01111"), ("sel_b", "10100"), ("opcode", "01011"), ("selp", "11"), "m7", "c7", "t2", "c4"],
    [("cond", "0110"), ("sel_a", "00000"), ("sel_b", "00000"), ("sel_c", "00000"), ("opcode", "01011"), "ma", ("mb", "10"), "t6", "c4"],
    [("ir_size", "00000"), ("ir_offset", "00011"), "t3", "c5"],
    ["b", "a0", "ma", ("mb", "01"), ("opcode", "01010"), "t6", "c2"],
    "blt",
    [("sel_a", "01111"), ("sel_b", "10100"), ("opcode", "01011"), ("selp", "11"), "m7", "c7", "t2", "c4"],
    [("cond", "1001"), "b", ("sel_a", "00000"), ("sel_b", "00000"), ("sel_c", "00000"), ("opcode", "01011"), "ma", ("mb", "10"), "t6", "c4"],
    [("ir_size", "00000"), ("ir_offset", "00011"), "t3", "c5"],
    ["b", "a0", "ma", ("mb", "01"), ("opcode", "01010"), "t6", "c2"],
    "bge",
    [("sel_a", "01111"), ("sel_b", "10100"), ("opcode", "01011"), ("selp", "11"), "m7", "c7", "t2", "c4"],
    [("cond", "1001"), ("sel_a", "00000"), ("sel_b", "00000"), ("sel_c", "00000"), ("opcode", "01011"), "ma", ("mb", "10"), "t6", "c4"],
    [("ir_size", "00000"), ("ir_offset", "00011"), "t3", "c5"],
    ["b", "a0", "ma", ("mb", "01"), ("opcode", "01010"), "t6", "c2"],
    "bltu",
    [("sel_a", "01111"), ("sel_b", "10100"), ("opcode", "10111"), ("selp", "11"), "m7", "c7", "t2", "c4"],
    [("cond", "1001"), "b", ("sel_a", "00000"), ("sel_b", "00000"), ("sel_c", "00000"), ("opcode", "01011"), "ma", ("mb", "10"), "t6", "c4"],
    [("ir_size", "00000"), ("ir_offset", "00011"), "t3", "c5"],
    ["b", "a0", "ma", ("mb", "01"), ("opcode", "01010"), "t6", "c2"],
    "bgeu",
    [("sel_a", "01111"), ("sel_b", "10100"), ("opcode", "10111"), ("selp", "11"), "m7", "c7", "t2", "c4"],
    [("cond", "1001"), ("sel_a", "00000"), ("sel_b", "00000"), ("sel_c", "00000"), ("opcode", "01011"), "ma", ("mb", "10"), "t6", "c4"],
    [("ir_size", "00000"), ("ir_offset", "00011"), "t3", "c5"],
    ["b", "a0", "ma", ("mb", "01"), ("opcode", "01010"), "t6", "c2"],
    "lb",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    [("sel_a", "01111"), ("mb", "01"), ("opcode", "01010"), "t6", "c0"],
    ["t13"],
    ["t13", "r", "m1", "c1", ("bw", "00"), "se"],
    ["b", "a0", ("sel_c", "00111"), "t1", "lc"],
    "lh",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    [("sel_a", "01111"), ("mb", "01"), ("opcode", "01010"), "t6", "c0"],
    ["t13"],
    ["t13", "r", "m1", "c1", ("bw", "01"), "se"],
    ["b", "a0", ("sel_c", "00111"), "t1", "lc"],
    "lw",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    [("sel_a", "01111"), ("mb", "01"), ("opcode", "01010"), "t6", "c0"],
    ["t13"],
    ["t13", "r", "m1", "c1", ("bw", "11"), "se"],
    ["b", "a0", ("sel_c", "00111"), "t1", "lc"],
    "lbu",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    [("sel_a", "01111"), ("mb", "01"), ("opcode", "01010"), "t6", "c0"],
    ["t13"],
    ["t13", "r", "m1", "c1", ("bw", "00")],
    ["b", "a0", ("sel_c", "00111"), "t1", "lc"],
    "lhu",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    [("sel_a", "01111"), ("mb", "01"), ("opcode", "01010"), "t6", "c0"],
    ["t13"],
    ["t13", "r", "m1", "c1", ("bw", "01")],
    ["b", "a0", ("sel_c", "00111"), "t1", "lc"],
    "sb",
    [("ir_size", "00000"), ("ir_offset", "00010"), "t3", "c5"],
    [("sel_a", "01111"), ("mb", "01"), ("opcode", "01010"), "t6", "c0"],
    [("sel_a", "10100"), "t9", "c1"],
    ["b", "a0", "w", "t13", "t14", ("bw", "00")],
    "sh",
    [("ir_size", "00000"), ("ir_offset", "00010"), "t3", "c5"],
    [("sel_a", "01111"), ("mb", "01"), ("opcode", "01010"), "t6", "c0"],
    [("sel_a", "10100"), "t9", "c1"],
    ["b", "a0", "w", "t13", "t14", ("bw", "01")],
    "sw",
    [("ir_size", "00000"), ("ir_offset", "00010"), "t3", "c5"],
    [("sel_a", "01111"), ("mb", "01"), ("opcode", "01010"), "t6", "c0"],
    [("sel_a", "10100"), "t9", "c1"],
    ["b", "a0", "w", "t13", "t14", ("bw", "11")],
    "addi",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    ["b", "a0", ("sel_a", "01111"), ("sel_c", "00111"), ("mb", "01"), ("opcode", "01010"), "t6", "lc"],
    "slti",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    [("sel_a", "01111"), ("mb", "01"), ("opcode", "01011"), ("selp", "11"), "m7", "c7"],
    [("cond", "1001"), "b", ("sel_a", "10000"), ("sel_b", "10100"), ("sel_c", "10000")], # jump to false
    ["b", "a0", ("sel_c", "00111"), "lc", ("ex_code", "0001"), "t11"],
    ["b", "a0", ("sel_c", "00111"), "lc", ("ex_code", "0000"), "t11"],
    "sltiu",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    [("sel_a", "01111"), ("mb", "01"), ("opcode", "10111"), ("selp", "11"), "m7", "c7"],
    [("cond", "1001"), "b", ("sel_a", "10000"), ("sel_b", "10101"), ("sel_c", "11000")], # jump to false
    ["b", "a0", ("sel_c", "00111"), "lc", ("ex_code", "0001"), "t11"],
    ["b", "a0", ("sel_c", "00111"), "lc", ("ex_code", "0000"), "t11"],
    "xori",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    ["b", "a0", ("sel_a", "01111"), ("sel_c", "00111"), ("mb", "01"), ("opcode", "00100"), "t6", "lc"],
    "ori",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    ["b", "a0", ("sel_a", "01111"), ("sel_c", "00111"), ("mb", "01"), ("opcode", "00010"), "t6", "lc"],
    "andi",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    ["b", "a0", ("sel_a", "01111"), ("sel_c", "00111"), ("mb", "01"), ("opcode", "00001"), "t6", "lc"],
    "slli",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    ["b", "a0", ("sel_a", "01111"), ("sel_c", "00111"), ("mb", "01"), ("opcode", "00111"), "t6", "lc"],
    "srli",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    ["b", "a0", ("sel_a", "01111"), ("sel_c", "00111"), ("mb", "01"), ("opcode", "00101"), "t6", "lc"],
    "srai",
    [("ir_size", "00000"), ("ir_offset", "00001"), "t3", "c5"],
    ["b", "a0", ("sel_a", "01111"), ("sel_c", "00111"), ("mb", "01"), ("opcode", "00110"), "t6", "lc"],
    "add",
    ["b", "a0", ("sel_a", "01111"), ("sel_b", "10100"), ("sel_c", "00111"), ("opcode", "01010"), "t6", "lc"],
    "sub",
    ["b", "a0", ("sel_a", "01111"), ("sel_b", "10100"), ("sel_c", "00111"), ("opcode", "01011"), "t6", "lc"],
    "sll",
    ["b", "a0", ("sel_a", "01111"), ("sel_b", "10100"), ("sel_c", "00111"), ("opcode", "00111"), "t6", "lc"],
    "slt",
    [("sel_a", "01111"), ("sel_b", "10100"), ("opcode", "01011"), ("selp", "11"), "m7", "c7"],
    [("cond", "1001"), "b", ("sel_a", "10000"), ("sel_b", "11010"), ("sel_c", "10000")], # jump to false
    ["b", "a0", ("sel_c", "00111"), "lc", ("ex_code", "0001"), "t11"],
    ["b", "a0", ("sel_c", "00111"), "lc", ("ex_code", "0000"), "t11"],
    "sltu",
    [("sel_a", "01111"), ("sel_b", "10100"), ("opcode", "10111"), ("selp", "11"), "m7", "c7"],
    [("cond", "1001"), "b", ("sel_a", "10000"), ("sel_b", "11011"), ("sel_c", "10000")], # jump to false
    ["b", "a0", ("sel_c", "00111"), "lc", ("ex_code", "0001"), "t11"],
    ["b", "a0", ("sel_c", "00111"), "lc", ("ex_code", "0000"), "t11"],
    "xor",
    ["b", "a0", ("sel_a", "01111"), ("sel_b", "10100"), ("sel_c", "00111"), ("opcode", "00100"), "t6", "lc"],
    "srl",
    ["b", "a0", ("sel_a", "01111"), ("sel_b", "10100"), ("sel_c", "00111"), ("opcode", "00101"), "t6", "lc"],
    "sra",
    ["b", "a0", ("sel_a", "01111"), ("sel_b", "10100"), ("sel_c", "00111"), ("opcode", "00110"), "t6", "lc"],
    "or",
    ["b", "a0", ("sel_a", "01111"), ("sel_b", "10100"), ("sel_c", "00111"), ("opcode", "00010"), "t6", "lc"],
    "and",
    ["b", "a0", ("sel_a", "01111"), ("sel_b", "10100"), ("sel_c", "00111"), ("opcode", "00001"), "t6", "lc"],
    "fence",
    ["b", "a0"],
    "ecall",
    [("cond", "0000"), "b", ("sel_a", "00000"), ("sel_b", "00010"), ("sel_c", "01000"), ("ex_code", "0010"), "t11", "c4"], # jump to csw_rt1
    "ebreak",
    ["b", "a0", "pause"],
    "mret",
    [("cond", "0100"), ("sel_a", "00000"), ("sel_b", "00000"), ("sel_c", "00000"), ("ex_code", "0000"), "t11", "c4"], # Check we are in kernel mode and raise illegal instruction otherwise
    ["mr", ("sel_a", "00010"), "t9", "c0"],
    ["mr", ("sel_a", "00010"), ("sel_c", "00010"), ("mb", "10"), ("opcode", "01010"), "t6", "lc", "t13"],
    ["t13", "r", "m1", "c1", ("bw", "11")],
    ["t1", "c7"],

    ["mr", ("sel_a", "00010"), "t9", "c0"],
    ["mr", ("sel_a", "00010"), ("sel_c", "00010"), ("mb", "10"), ("opcode", "01010"), "t6", "lc", "t13"],
    ["t13", "r", "m1", "c1", ("bw", "11")],
    ["b", "a0", "t1", "c2"],

    # RV32Zmmul
    "mul",
    ["b", "a0", ("sel_a", "01111"), ("sel_b", "10100"), ("sel_c", "00111"), ("opcode", "01100"), "t6", "lc"],
    "mulh",
    ["b", "a0", ("sel_a", "01111"), ("sel_b", "10100"), ("sel_c", "00111"), ("opcode", "11010"), "t6", "lc"],
    "mulhsu",
    ["b", "a0", ("sel_a", "01111"), ("sel_b", "10100"), ("sel_c", "00111"), ("opcode", "11100"), "t6", "lc"],
    "mulhu",
    ["b", "a0", ("sel_a", "01111"), ("sel_b", "10100"), ("sel_c", "00111"), ("opcode", "11011"), "t6", "lc"],

    # Custom extensions
    "in",
    [("cond", "0100"), ("sel_a", "00000"), ("sel_b", "00000"), ("sel_c", "00000"), ("ex_code", "0000"), "t11", "c4"], # Check we are in kernel mode and raise illegal instruction otherwise
    [("ir_size", "10000"), ("ir_offset", "10000"), ("se", False), "t3", "c0"],
    ["t13", "ior", "m1", "c1"],
    ["b", "a0", ("sel_c", "00111"), "t1", "lc"],
    "out",
    [("cond", "0100"), ("sel_a", "00000"), ("sel_b", "00000"), ("sel_c", "00000"), ("ex_code", "0000"), "t11", "c4"], # Check we are in kernel mode and raise illegal instruction otherwise
    [("ir_size", "10000"), ("ir_offset", "10000"), ("se", False), "t3", "c0"],
    [("sel_a", "00111"), "t9", "c1"],
    ["b", "a0", "iow", "t13", "t14"],

    "illegal instruction",
    [("cond", "0000"), "b", ("sel_a", "00000"), ("sel_b", "00010"), ("sel_c", "01000"), ("ex_code", "0000"), "t11", "c4", "pause"], # jump to csw_rt1

    0b111110000000,
    "bootloader",
    # Init
    # x1 <- Load read addr
    [("ex_code", "0001"), "t11", "c4"],
    [("ex_code", "1000"), "t11", "c5"],
    ["ma", ("mb", "01"), ("opcode", "00111"), "t6", "mr", "lc", ("sel_c", "00001")], # x1 <- 1 sll 8 = 0x0100
    # Read segment header
    [("ex_code", "0001"), "t11", "mr", "lc", ("sel_c", "11111")],      # setup return code
    ["b", ("sel_a", "11111"), ("sel_b", "11000"), ("sel_c", "00000")], # read UART word
    ["mr", "lc", ("sel_a", "00011"), ("sel_c", "00100"), "t9"],        # x4 <- x3 (addr)
    [("ex_code", "0010"), "t11", "mr", "lc", ("sel_c", "11111")],      # setup return code
    ["b", ("sel_a", "11111"), ("sel_b", "11000"), ("sel_c", "00000")], # read UART word
    # x5 <- x3 * 4 (size)
    ["mr", "lc", ("sel_a", "00011"), ("sel_c", "00101"), ("mb", "10"), ("opcode", "01100"), "t6"],
    # if x4 == 0 && x5 == 0 (x4 | x5 == 0), stop loading
    ["mr", ("sel_a", "00100"), ("sel_b", "00101"), ("opcode", "00010"), ("selp", "11"), "m7", "c7"],
    [("cond", "0110"), ("sel_a", "11111"), ("sel_b", "00100"), ("sel_c", "10000")],
    # Read segment
    # do while x5 > 0
        [("ex_code", "0000"), "t11", "mr", "lc", ("sel_c", "11110")],      # setup return code
        ["b", ("sel_a", "11111"), ("sel_b", "10000"), ("sel_c", "00000")], # read UART byte
        # MEM[x4] <- x3
        ["mr", ("sel_a", "00100"), "t9", "c0"], # mar <- addr
        [
            "w", "t13", "t14", ("bw", "00"), # write to RAM
            "mr", "lc", ("sel_a", "00100"), ("sel_c", "00100"), ("mb", "11"), ("opcode", "01010"), "t6", # x4 += 1 (addr)
        ],
        # x5 += -1
        ["mr", "lc", ("sel_a", "00101"), ("sel_c", "00101"), ("mb", "11"), ("opcode", "01011"), "t6", ("selp", "11"), "m7", "c7"],
        # if x5 != 0, loop
        [("cond", "0110"), "b", ("sel_a", "11111"), ("sel_b", "00010"), ("sel_c", "11000")],
    ["b", ("sel_a", "11111"), ("sel_b", "00000"), ("sel_c", "11000")], # Loop read segment header
    # Stop loading
    # Read entrypoint
    [("ex_code", "0011"), "t11", "mr", "lc", ("sel_c", "11111")],      # setup return code
    ["b", ("sel_a", "11111"), ("sel_b", "11000"), ("sel_c", "00000")], # read UART word
    [
        "mr", ("sel_a", "00011"), "t9", "c2", # pc <- x3 (entrypoint)
        "b", "a0", # Start running user code
    ],

    # read byte, store result in mbr
    0b111111000000,
    "read_byte_uart",
    [("ex_code", "0000"), "t11", "c4", "c1", ("selp", "11"), "m7", "c7"], # reset flag registers
    ["mr", ("sel_a", "00001"), ("mb", "10"), ("opcode", "01010"), "t6", "c0"], # mar <- read status addr
    ["t13", "ior", "m1", "c1", "t1", "c4", "ma", ("mb", "11"), ("opcode", "00001"), ("selp", "11"), "m7", "c7", ("cond", "0110"), ("sel_a", "11111"), ("sel_b", "10000"), ("sel_c", "10000")], # Spin lock
    ["mr", ("sel_a", "00001"), "t9", "c0"], # mar <- read addr
    ["t13", "ior", "m1", "c1"], # mbr <- UART byte
    # select return maddr based on x30
    # if x30 | 0 == 0 return to read section byte
    ["mr", ("sel_a", "11110"), ("opcode", "00010"), ("selp", "11"), "m7", "c7"],
    [("cond", "0110"), ("sel_a", "11111"), ("sel_b", "00011"), ("sel_c", "01000")],
    # else return to read word byte
    ["b", ("sel_a", "11111"), ("sel_b", "11001"), ("sel_c", "00000")],

    # read word in little endian. Store result in x3
    0b111111100000,
    "read_word_uart",
    [("ex_code", "0100"), "t11", "mr", "lc", ("sel_c", "00010")], # x2 <- 4 (counter)
    [("ex_code", "0000"), "t11", "mr", "lc", ("sel_c", "00011")], # x3 <- 0 (word buf)
    # do while x2 > 0
        [("ex_code", "0001"), "t11", "mr", "lc", ("sel_c", "11110")],      # setup return code
        ["b", ("sel_a", "11111"), ("sel_b", "10000"), ("sel_c", "00000")], # read UART byte
        ["t1", "c4"], # rt1 <- UART byte
        # add byte to accumulator (x3 <- (x3 | byte) ror 8)
        ["mr", "ma", ("sel_b", "00011"), ("opcode", "00010"), "t6", "c4"], # rt1 <- x3 | byte
        ["ma", ("mb", "01"), ("opcode", "01000"), "t6", "mr", "lc", ("sel_c", "00011")], # x3 <- rt1 ror 8
        ["mr", "lc", ("sel_a", "00010"), ("sel_c", "00010"), ("mb", "11"), ("opcode", "01011"), "t6", ("selp", "11"), "m7", "c7"], # x2 += -1
        # if x2 != 0, loop
        [("cond", "0110"), "b", ("sel_a", "11111"), ("sel_b", "11000"), ("sel_c", "10000")],
    # select return maddr based on x31
    # if x31 - 1 == 0 (x31 == 1) return to read section addr
    ["mr", "lc", ("sel_a", "11111"), ("sel_c", "11111"), ("mb", "11"), ("opcode", "01011"), "t6", ("selp", "11"), "m7", "c7"],
    [("cond", "0110"), ("sel_a", "11111"), ("sel_b", "00001"), ("sel_c", "01000")],
    # if x31 - 2 == 0 (x31 == 2) return to read section size
    ["mr", "lc", ("sel_a", "11111"), ("sel_c", "11111"), ("mb", "11"), ("opcode", "01011"), "t6", ("selp", "11"), "m7", "c7"],
    [("cond", "0110"), ("sel_a", "11111"), ("sel_b", "00010"), ("sel_c", "00000")],
    # else return to read entry point
    ["b", ("sel_a", "11111"), ("sel_b", "00101"), ("sel_c", "00000")],
]  # fmt: skip

INDENTATION: Final[int] = 8


def to_vhdl(x: Value) -> str:
    if isinstance(x, bool):
        return f"'{int(x)}'"
    return f'"{x}"'


def to_bin_addr(x: int) -> str:
    return f"{x:012b}"


NULL_MICROINSTRUCTION: Final[dict[str, Value]] = {
    "cond": "0000",
    "b": False,
    "a0": False,
    "mr": False,
    "sel_a": "00000",
    "sel_b": "00000",
    "sel_c": "00000",
    "lc": False,
    "t": "00000000000000",
    "c": "00000000",
    "ma": False,
    "m1": False,
    "m2": False,
    "m7": False,
    "mh": False,
    "mb": "00",
    "opcode": "00000",
    "se": False,
    "ir_size": "00000",
    "ir_offset": "00000",
    "bw": "00",
    "w": False,
    "r": False,
    "iow": False,
    "ior": False,
    "inta": False,
    "selp": "00",
    "interrupts": False,
    "user": False,
    "ex_code": "0000",
    "pause": False,
}


def print_instruction(inst: dict[str, Value], addr: str | int, end: str = ","):
    res = " " * INDENTATION + f"{addr} => ("
    for name, value in inst.items():
        res += f"{name} => {to_vhdl(value)}, "
    res = res[:-2] + ")" + end
    print(res)


addr = 0
opcode_addrs: list[tuple[str, int]] = []
for inst in MEMORY:
    if isinstance(inst, int):
        addr = inst
        continue
    if isinstance(inst, str):
        print(" " * INDENTATION + f"-- {inst}")
        opcode_addrs.append((inst, addr))
        continue
    curr = NULL_MICROINSTRUCTION.copy()
    for signal in inst:
        name, value = (signal, True) if isinstance(signal, str) else signal
        if re.match(r"^[ct]\d+$", name):
            off = 0 if name[0] == "c" else 1
            idx = int(name[1:]) - off
            name = name[0]
            prev = curr[name]
            value = prev[:idx] + str(int(value)) + prev[idx + 1 :]  # pyright: ignore
        curr[name] = value
    print_instruction(curr, addr)
    addr += 1
print_instruction(NULL_MICROINSTRUCTION, "others", end="")

print("\n" + "=" * 39 + "\n")
for inst, addr in opcode_addrs:
    print(" " * INDENTATION + f'"{to_bin_addr(addr)}", -- {inst}')
print(" " * INDENTATION + "others => (others => '0')")
