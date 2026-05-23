import re
from dataclasses import dataclass
from typing import Final, Iterable, Optional, TypeAlias

MicroInstruction: TypeAlias = dict[str, int]
Lines: TypeAlias = list[str]

FIELD_SIZE: Final[MicroInstruction] = {
    "cond": 4,
    "b": 1,
    "a0": 1,
    "mr": 1,
    "sela": 5,
    "selb": 5,
    "selc": 5,
    "lc": 1,
    "t": 12,
    "ta": 1,
    "td": 1,
    "c": 8,
    "ma": 1,
    "m1": 1,
    "m2": 1,
    "m7": 1,
    "mh": 1,
    "mb": 2,
    "cop": 5,
    "se": 1,
    "size": 5,
    "offset": 5,
    "bw": 2,
    "w": 1,
    "r": 1,
    "iow": 1,
    "ior": 1,
    "inta": 1,
    "selp": 2,
    "i": 1,
    "u": 1,
    "excode": 4,
    "pause": 1,
}


@dataclass
class MicroProgram:
    name: str
    pattern: Optional[str]
    start: int
    microcode: list[dict[str, int]]


def binary(x: int, size: int) -> str:
    res = bin(x)[2:]
    return res.zfill(size)


def null_microinstruction():
    return {k: 0 for k in FIELD_SIZE.keys()}


def parse_microinstruction(inst: dict[str, int]) -> MicroInstruction:
    curr = null_microinstruction()
    for name, value in inst.items():
        name = name.lower()
        if name == "maddr":
            curr["sela"] = (value >> 7) & 0x1F
            curr["selb"] = (value >> 2) & 0x1F
            curr["selc"] = (value & 0b11) << 3
            continue
        if re.match(r"^[ct]\d+$", name):
            off = int(name[0] == "t")
            idx = int(name[1:]) - off
            name = name[0]
            size = FIELD_SIZE[name]
            value = curr[name] | (1 << (size - idx - 1))
        elif name == "c":
            name = "cond"
        elif name not in curr:
            print("Unknown field name:", name)
            continue
        curr[name] = value
    return curr


def value_to_vhdl(x: int, size: int) -> str:
    return f"'{x}'" if size == 1 else f'"{binary(x, size)}"'


def microinstruction_to_vhdl(inst: MicroInstruction) -> str:
    signals = [
        f"{name} => {value_to_vhdl(value, FIELD_SIZE[name])}"
        for name, value in inst.items()
    ]
    return f"({', '.join(signals)})"


def control_memory_gen(firmware: list[MicroProgram]) -> Iterable[str]:
    for program in firmware:
        yield f"-- {program.name}"
        for i, inst in enumerate(program.microcode):
            inst = parse_microinstruction(inst)
            addr = program.start + i
            yield f"{addr} => {microinstruction_to_vhdl(inst)},"
    yield f"others => {microinstruction_to_vhdl(null_microinstruction())}"


def microcode_gen(firmware: list[MicroProgram]) -> tuple[Lines, Lines, Lines]:
    control_memory = list(control_memory_gen(firmware))

    instructions = [x for x in firmware if x.pattern is not None]
    names = [x.name for x in instructions]

    def format_list(elements: Iterable[str]) -> Lines:
        elements = list(elements)
        char = (" " if i == len(elements) - 1 else "," for i in range(len(elements)))
        return [f"{e}{c} -- {n}" for e, c, n in zip(elements, char, names)]

    patterns = format_list(f'"{x.pattern}"' for x in instructions)
    addrs = format_list(f'"{binary(x.start, 12)}"' for x in instructions)
    return control_memory, patterns, addrs
