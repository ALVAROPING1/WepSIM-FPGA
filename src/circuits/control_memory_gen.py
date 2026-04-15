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
        if name[0] in "ct" and re.match(r"\d+", name[1:]):
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
