from dataclasses import dataclass
from typing import Any, Final

from firmware.control_memory import MicroProgram, binary, microcode_gen
from firmware.immediate_decoder import Encoding, decoder_gen


@dataclass
class Firmware:
    encodings: list[Encoding]
    microprograms: list[MicroProgram]
    endianness: str
    start: int

    @classmethod
    def from_json(cls, data: dict[str, Any]) -> "Firmware":
        encodings = [Encoding(**x) for x in data["encodings"]]
        microprograms = [MicroProgram(**x) for x in data["microprograms"]] + BOOTLOADER
        return cls(encodings, microprograms, data["endianness"], data["start"])

    def gen(self) -> str:
        control_memory, patterns, addrs = microcode_gen(self.microprograms)
        instructions = len(patterns)
        control_memory, patterns, addrs = (
            "\n".join(" " * 8 + x for x in lines)
            for lines in (control_memory, patterns, addrs)
        )

        decoder_header, decoder_body = decoder_gen(self.encodings)

        return f"""library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.firmware_types.all;

package firmware is
    constant control_memory: ControlMemoryROM := (
{control_memory}
    );
    constant patterns: OpcodePatterns(0 to {instructions - 1}) := (
{patterns}
    );
    constant addrs: OpcodeTable(patterns'range) := (
{addrs}
    );
    constant cu_start: ControlMemoryAddr := "{binary(self.start, 12)}";

    constant little_endian: boolean := {str(self.endianness == "little").lower()};

    {decoder_header};
end package;

package body firmware is
    {decoder_header} {decoder_body}
end package body;"""


BOOTLOADER: Final[list[MicroProgram]] = [
    MicroProgram("bootloader", None, 0b111110000000, [
        # Init
        # x1 <- Load read addr
        {"excode": 1, "t11": 1, "c4": 1},
        {"excode": 8, "t11": 1, "c5": 1},
        {"ma": 1, "mb": 0b01, "cop": 0b00111, "t6": 1, "mr": 1, "lc": 1, "selc": 1}, # x1 <- 1 sll 8
        # Read segment header
        "read_header",
        {"excode": 1, "t11": 1, "mr": 1, "lc": 1, "selc": 31}, # setup return code
        {"b": 1, "maddr": "read_word_uart"},                   # read UART word
        "read_addr",
        {"mr": 1, "lc": 1, "sela": 3, "selc": 4, "t9": 1},     # x4 <- x3 (addr)
        {"excode": 2, "t11": 1, "mr": 1, "lc": 1, "selc": 31}, # setup return code
        {"b": 1, "maddr": "read_word_uart"},                   # read UART word
        "read_size",
        # x5 <- x3 * 4 (size)
        {"mr": 1, "lc": 1, "sela": 3, "selc": 5, "mb": 0b10, "cop": 0b01100, "t6": 1},
        # if x4 == 0 && x5 == 0 (x4 | x5 == 0), stop loading
        {"mr": 1, "sela": 4, "selb": 5, "cop": 0b00010, "selp": 0b11, "m7": 1, "c7": 1},
        {"cond": 6, "maddr": "stop_loading"},
        # Read segment
        # do while x5 > 0
            "read_segment",
            {"excode": 0, "t11": 1, "mr": 1, "lc": 1, "selc": 30}, # setup return code
            {"b": 1, "maddr": "read_byte_uart"},                   # read UART byte
            "read_section_byte",
            # MEM[x4++] <- x3
            {"mr": 1, "sela": 4, "t9": 1, "c0": 1}, # mar <- addr
            {
                "w": 1, "ta": 1, "td": 1, "bw": 0b00, # write to RAM
                "mr": 1, "lc": 1, "sela": 4, "selc": 4, "mb": 0b11, "cop": 0b01010, "t6": 1, # x4 += 1 (addr)
            },
            # x5 += -1
            {"mr": 1, "lc": 1, "sela": 5, "selc": 5, "mb": 0b11, "cop": 0b01011, "t6": 1, "selp": 0b11, "m7": 1, "c7": 1},
            # if x5 != 0, loop
            {"cond": 6, "b": 1, "maddr": "read_segment"},
        {"b": 1, "maddr": "read_header"}, # Loop read segment header
        # Stop loading
        # Read entrypoint
        "stop_loading",
        {"excode": 3, "t11": 1, "mr": 1, "lc": 1, "selc": 31}, # setup return code
        {"b": 1, "maddr": "read_word_uart"},                   # read UART word
        "read_entrypoint",
        {
            "mr": 1, "sela": 3, "t9": 1, "c2": 1, # pc <- x3 (entrypoint)
            "b": 1, "a0": 1, # Start running user code
        },
    ]),

    # read byte, store result in mbr
    MicroProgram("read_byte_uart", None, 0b111111000000, [
        {"excode": 0, "t11": 1, "c4": 1, "c1": 1, "selp": 0b11, "m7": 1, "c7": 1}, # reset flag registers
        {"mr": 1, "sela": 1, "mb": 0b10, "cop": 0b01010, "t6": 1, "c0": 1},        # mar <- read status addr
        "spin_lock", {"ta": 1, "ior": 1, "m1": 1, "c1": 1, "t1": 1, "c4": 1, "ma": 1, "mb": 0b11, "cop": 0b00001, "selp": 0b11, "m7": 1, "c7": 1, "cond": 6, "maddr": "spin_lock"}, # Spin lock
        {"mr": 1, "sela": 1, "t9": 1, "c0": 1}, # mar <- read addr
        {"ta": 1, "ior": 1, "m1": 1, "c1": 1},  # mbr <- UART byte
        # select return maddr based on x30
        # if x30 | 0 == 0 return to read section byte
        {"mr": 1, "sela": 30, "cop": 0b00010, "selp": 0b11, "m7": 1, "c7": 1},
        {"cond": 6, "maddr": "read_section_byte"},
        # else return to read word byte
        {"b": 1, "maddr": "read_word_byte"},
    ]),

    # read word in little endian. Store result in x3
    MicroProgram("read_word_uart", None, 0b111111100000, [
        {"excode": 4, "t11": 1, "mr": 1, "lc": 1, "selc": 2}, # x2 <- 4 (counter)
        {"excode": 0, "t11": 1, "mr": 1, "lc": 1, "selc": 3}, # x3 <- 0 (word buf)
        # do while x2 > 0
            "byte_loop",
            {"excode": 1, "t11": 1, "mr": 1, "lc": 1, "selc": 30}, # setup return code
            {"b": 1, "maddr": "read_byte_uart"},                   # read UART byte
            "read_word_byte",
            {"t1": 1, "c4": 1},                                    # rt1 <- UART byte
            # add byte to accumulator (x3 <- (x3 | byte) ror 8)
            {"mr": 1, "ma": 1, "selb": 3, "cop": 0b00010, "t6": 1, "c4": 1},             # rt1 <- x3 | byte
            {"ma": 1, "mb": 0b01, "cop": 0b01000, "t6": 1, "mr": 1, "lc": 1, "selc": 3}, # x3 <- rt1 ror 8
            {"mr": 1, "lc": 1, "sela": 2, "selc": 2, "mb": 0b11, "cop": 0b01011, "t6": 1, "selp": 0b11, "m7": 1, "c7": 1}, # x2 += -1
            # if x2 != 0, loop
            {"cond": 6, "b": 1, "maddr": "byte_loop"},
        # select return maddr based on x31
        # if x31 - 1 == 0 (x31 == 1) return to read section addr
        {"mr": 1, "lc": 1, "sela": 31, "selc": 31, "mb": 0b11, "cop": 0b01011, "t6": 1, "selp": 0b11, "m7": 1, "c7": 1},
        {"cond": 6, "maddr": "read_addr"},
        # if x31 - 2 == 0 (x31 == 2) return to read section size
        {"mr": 1, "lc": 1, "sela": 31, "selc": 31, "mb": 0b11, "cop": 0b01011, "t6": 1, "selp": 0b11, "m7": 1, "c7": 1},
        {"cond": 6, "maddr": "read_size"},
        # else return to read entry point
        {"b": 1, "maddr": "read_entrypoint"},
    ]),
]  # fmt: skip

if __name__ == "__main__":
    microprograms = [
        ("begin", None, 0, [
            {"mr": 1, "selc": 0, "excode": 0, "t11": 1, "lc": 1},
            # Check async interrupts
            {"cond": 1, "maddr": "mrti"},
            # Fetch
            "fetch",
            {"t2": 1, "c0": 1},
            {"ta": 1},
            {"r": 1, "m1": 1, "c1": 1, "bw": 0b11},
            {"m2": 1, "c2": 1, "t1": 1, "c3": 1},
            {"a0": 1, "b": 0},
            # mrti
            "mrti",
            {"inta": 1, "m1": 1, "c1": 1},
            {"t1": 1, "c4": 1},
            # csw_rt1
            "csw_rt1",
            {"mr": 1, "sela": 2, "selc": 2, "mb": 0b10, "cop": 0b01011, "t6": 1, "lc": 1, "c0": 1},
            {"t2": 1, "c1": 1},
            {"w": 1, "ta": 1, "td": 1, "bw": 0b11},

            {"mr": 1, "sela": 2, "selc": 2, "mb": 0b10, "cop": 0b01011, "t6": 1, "lc": 1, "c0": 1},
            {"t8": 1, "c1": 1},
            {"w": 1, "ta": 1, "td": 1, "bw": 0b11},

            {"ma": 1, "mb": 0b10, "cop": 0b01100, "t6": 1, "c0": 1},

            {"ta": 1},
            {"ta": 1, "r": 1, "m1": 1, "c1": 1, "bw": 0b11},

            {"cond": 0, "b": 1, "maddr": "fetch", "c2": 1, "t1": 1, "selp": 0b01, "u": 0, "m7": 1, "c7": 1},
        ]),
        # RV32I
        ("lui", "-------------------------0110111", 2048, [
            {"b": 1, "a0": 1, "selc": 7, "offset": 4, "t3": 1, "lc": 1},
        ]),
        ("auipc", "-------------------------0010111", 2049, [
            {"t2": 1, "c4": 1},
            {"cop": 0b01011, "ma": 1, "mb": 0b10, "t6": 1, "c4": 1},
            {"offset": 4, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "selc": 7, "cop": 0b01010, "ma": 1, "mb": 0b01, "t6": 1, "lc": 1},
        ]),
        ("jal", "-------------------------1101111", 2053, [
            {"selc": 7, "t2": 1, "lc": 1},
            {"t2": 1, "c4": 1},
            {"cop": 0b01011, "ma": 1, "mb": 0b10, "t6": 1, "c4": 1},
            {"offset": 5, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "cop": 0b01010, "ma": 1, "mb": 0b01, "t6": 1, "c2": 1},
        ]),
        ("jalr", "-----------------000-----1100111", 2058, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"sela": 15, "cop": 0b01010, "mb": 0b01, "t6": 1, "c4": 1},
            {"cop": 0b00101, "ma": 1, "mb": 0b11, "t6": 1, "c4": 1},
            {"selc": 7, "cop": 0b00111, "ma": 1, "mb": 0b11, "c6": 1, "t2": 1, "lc": 1},
            {"b": 1, "a0": 1, "t7": 1, "c2": 1},
        ]),
        ("beq", "-----------------000-----1100011", 2063, [
            {"sela": 15, "selb": 20, "cop": 0b01011, "selp": 0b11, "m7": 1, "c7": 1, "t2": 1, "c4": 1},
            {"cond": 6, "b": 1, "maddr": 0, "cop": 0b01011, "ma": 1, "mb": 0b10, "t6": 1, "c4": 1},
            {"offset": 3, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "ma": 1, "mb": 0b01, "cop": 0b01010, "t6": 1, "c2": 1},
        ]),
        ("bne", "-----------------001-----1100011", 2067, [
            {"sela": 15, "selb": 20, "cop": 0b01011, "selp": 0b11, "m7": 1, "c7": 1, "t2": 1, "c4": 1},
            {"cond": 6, "maddr": 0, "cop": 0b01011, "ma": 1, "mb": 0b10, "t6": 1, "c4": 1},
            {"offset": 3, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "ma": 1, "mb": 0b01, "cop": 0b01010, "t6": 1, "c2": 1},
        ]),
        ("blt", "-----------------100-----1100011", 2071, [
            {"sela": 15, "selb": 20, "cop": 0b01011, "selp": 0b11, "m7": 1, "c7": 1, "t2": 1, "c4": 1},
            {"cond": 9, "b": 1, "maddr": 0, "cop": 0b01011, "ma": 1, "mb": 0b10, "t6": 1, "c4": 1},
            {"offset": 3, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "ma": 1, "mb": 0b01, "cop": 0b01010, "t6": 1, "c2": 1},
        ]),
        ("bge", "-----------------101-----1100011", 2075, [
            {"sela": 15, "selb": 20, "cop": 0b01011, "selp": 0b11, "m7": 1, "c7": 1, "t2": 1, "c4": 1},
            {"cond": 9, "maddr": 0, "cop": 0b01011, "ma": 1, "mb": 0b10, "t6": 1, "c4": 1},
            {"offset": 3, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "ma": 1, "mb": 0b01, "cop": 0b01010, "t6": 1, "c2": 1},
        ]),
        ("bltu", "-----------------110-----1100011", 2079, [
            {"sela": 15, "selb": 20, "cop": 0b10111, "selp": 0b11, "m7": 1, "c7": 1, "t2": 1, "c4": 1},
            {"cond": 9, "b": 1, "maddr": 0, "cop": 0b01011, "ma": 1, "mb": 0b10, "t6": 1, "c4": 1},
            {"offset": 3, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "ma": 1, "mb": 0b01, "cop": 0b01010, "t6": 1, "c2": 1},
        ]),
        ("bgeu", "-----------------111-----1100011", 2083, [
            {"sela": 15, "selb": 20, "cop": 0b10111, "selp": 0b11, "m7": 1, "c7": 1, "t2": 1, "c4": 1},
            {"cond": 9, "maddr": 0, "cop": 0b01011, "ma": 1, "mb": 0b10, "t6": 1, "c4": 1},
            {"offset": 3, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "ma": 1, "mb": 0b01, "cop": 0b01010, "t6": 1, "c2": 1},
        ]),
        ("lb", "-----------------000-----0000011", 2087, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"sela": 15, "mb": 0b01, "cop": 0b01010, "t6": 1, "c0": 1},
            {"ta": 1},
            {"ta": 1, "r": 1, "m1": 1, "c1": 1, "bw": 0b00, "se": 1},
            {"b": 1, "a0": 1, "selc": 7, "t1": 1, "lc": 1},
        ]),
        ("lh", "-----------------001-----0000011", 2092, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"sela": 15, "mb": 0b01, "cop": 0b01010, "t6": 1, "c0": 1},
            {"ta": 1},
            {"ta": 1, "r": 1, "m1": 1, "c1": 1, "bw": 0b01, "se": 1},
            {"b": 1, "a0": 1, "selc": 7, "t1": 1, "lc": 1},
        ]),
        ("lw", "-----------------010-----0000011", 2097, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"sela": 15, "mb": 0b01, "cop": 0b01010, "t6": 1, "c0": 1},
            {"ta": 1},
            {"ta": 1, "r": 1, "m1": 1, "c1": 1, "bw": 0b11, "se": 1},
            {"b": 1, "a0": 1, "selc": 7, "t1": 1, "lc": 1},
        ]),
        ("lbu", "-----------------100-----0000011", 2102, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"sela": 15, "mb": 0b01, "cop": 0b01010, "t6": 1, "c0": 1},
            {"ta": 1},
            {"ta": 1, "r": 1, "m1": 1, "c1": 1, "bw": 0b00},
            {"b": 1, "a0": 1, "selc": 7, "t1": 1, "lc": 1},
        ]),
        ("lhu", "-----------------101-----0000011", 2107, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"sela": 15, "mb": 0b01, "cop": 0b01010, "t6": 1, "c0": 1},
            {"ta": 1},
            {"ta": 1, "r": 1, "m1": 1, "c1": 1, "bw": 0b01},
            {"b": 1, "a0": 1, "selc": 7, "t1": 1, "lc": 1},
        ]),
        ("sb", "-----------------000-----0100011", 2112, [
            {"offset": 2, "t3": 1, "c5": 1},
            {"sela": 15, "mb": 0b01, "cop": 0b01010, "t6": 1, "c0": 1},
            {"sela": 20, "t9": 1, "c1": 1},
            {"b": 1, "a0": 1, "w": 1, "ta": 1, "td": 1, "bw": 0b00},
        ]),
        ("sh", "-----------------001-----0100011", 2116, [
            {"offset": 2, "t3": 1, "c5": 1},
            {"sela": 15, "mb": 0b01, "cop": 0b01010, "t6": 1, "c0": 1},
            {"sela": 20, "t9": 1, "c1": 1},
            {"b": 1, "a0": 1, "w": 1, "ta": 1, "td": 1, "bw": 0b01},
        ]),
        ("sw", "-----------------010-----0100011", 2120, [
            {"offset": 2, "t3": 1, "c5": 1},
            {"sela": 15, "mb": 0b01, "cop": 0b01010, "t6": 1, "c0": 1},
            {"sela": 20, "t9": 1, "c1": 1},
            {"b": 1, "a0": 1, "w": 1, "ta": 1, "td": 1, "bw": 0b11},
        ]),
        ("addi", "-----------------000-----0010011", 2124, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "sela": 15, "selc": 7, "mb": 0b01, "cop": 0b01010, "t6": 1, "lc": 1},
        ]),
        ("slti", "-----------------010-----0010011", 2126, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"sela": 15, "mb": 0b01, "cop": 0b01011, "selp": 0b11, "m7": 1, "c7": 1},
            {"cond": 9, "b": 1, "maddr": "slti0"},
            {         "b": 1, "a0": 1, "selc": 7, "lc": 1, "excode": 1, "t11": 1},
            "slti0", {"b": 1, "a0": 1, "selc": 7, "lc": 1, "excode": 0, "t11": 1},
        ]),
        ("sltiu", "-----------------011-----0010011", 2131, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"sela": 15, "mb": 0b01, "cop": 0b10111, "selp": 0b11, "m7": 1, "c7": 1},
            {"cond": 9, "b": 1, "maddr": "sltiu0"},
            {          "b": 1, "a0": 1, "selc": 7, "lc": 1, "excode": 1, "t11": 1},
            "sltiu0", {"b": 1, "a0": 1, "selc": 7, "lc": 1, "excode": 0, "t11": 1},
        ]),
        ("xori", "-----------------100-----0010011", 2136, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "sela": 15, "selc": 7, "mb": 0b01, "cop": 0b00100, "t6": 1, "lc": 1},
        ]),
        ("ori", "-----------------110-----0010011", 2138, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "sela": 15, "selc": 7, "mb": 0b01, "cop": 0b00010, "t6": 1, "lc": 1},
        ]),
        ("andi", "-----------------111-----0010011", 2140, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "sela": 15, "selc": 7, "mb": 0b01, "cop": 0b00001, "t6": 1, "lc": 1},
        ]),
        ("slli", "0000000----------001-----0010011", 2142, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "sela": 15, "selc": 7, "mb": 0b01, "cop": 0b00111, "t6": 1, "lc": 1},
        ]),
        ("srli", "0000000----------101-----0010011", 2144, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "sela": 15, "selc": 7, "mb": 0b01, "cop": 0b00101, "t6": 1, "lc": 1},
        ]),
        ("srai", "0100000----------101-----0010011", 2146, [
            {"offset": 1, "t3": 1, "c5": 1},
            {"b": 1, "a0": 1, "sela": 15, "selc": 7, "mb": 0b01, "cop": 0b00110, "t6": 1, "lc": 1},
        ]),
        ("add", "0000000----------000-----0110011", 2148, [
            {"b": 1, "a0": 1, "sela": 15, "selb": 20, "selc": 7, "cop": 0b01010, "t6": 1, "lc": 1},
        ]),
        ("sub", "0100000----------000-----0110011", 2149, [
            {"b": 1, "a0": 1, "sela": 15, "selb": 20, "selc": 7, "cop": 0b01011, "t6": 1, "lc": 1},
        ]),
        ("sll", "0000000----------001-----0110011", 2150, [
            {"b": 1, "a0": 1, "sela": 15, "selb": 20, "selc": 7, "cop": 0b00111, "t6": 1, "lc": 1},
        ]),
        ("slt", "0000000----------010-----0110011", 2151, [
            {"sela": 15, "selb": 20, "cop": 0b01011, "selp": 0b11, "m7": 1, "c7": 1},
            {"cond": 9, "b": 1, "maddr": "slt0"},
            {        "b": 1, "a0": 1, "selc": 7, "lc": 1, "excode": 1, "t11": 1},
            "slt0", {"b": 1, "a0": 1, "selc": 7, "lc": 1, "excode": 0, "t11": 1},
        ]),
        ("sltu", "0000000----------011-----0110011", 2155, [
            {"sela": 15, "selb": 20, "cop": 0b10111, "selp": 0b11, "m7": 1, "c7": 1},
            {"cond": 9, "b": 1, "maddr": "sltu0"},
            {         "b": 1, "a0": 1, "selc": 7, "lc": 1, "excode": 1, "t11": 1},
            "sltu0", {"b": 1, "a0": 1, "selc": 7, "lc": 1, "excode": 0, "t11": 1},
        ]),
        ("xor", "0000000----------100-----0110011", 2159, [
            {"b": 1, "a0": 1, "sela": 15, "selb": 20, "selc": 7, "cop": 0b00100, "t6": 1, "lc": 1},
        ]),
        ("srl", "0000000----------101-----0110011", 2160, [
            {"b": 1, "a0": 1, "sela": 15, "selb": 20, "selc": 7, "cop": 0b00101, "t6": 1, "lc": 1},
        ]),
        ("sra", "0100000----------101-----0110011", 2161, [
            {"b": 1, "a0": 1, "sela": 15, "selb": 20, "selc": 7, "cop": 0b00110, "t6": 1, "lc": 1},
        ]),
        ("or", "0000000----------110-----0110011", 2162, [
            {"b": 1, "a0": 1, "sela": 15, "selb": 20, "selc": 7, "cop": 0b00010, "t6": 1, "lc": 1},
        ]),
        ("and", "0000000----------111-----0110011", 2163, [
            {"b": 1, "a0": 1, "sela": 15, "selb": 20, "selc": 7, "cop": 0b00001, "t6": 1, "lc": 1},
        ]),
        ("fence", "-----------------000-----0001111", 2164, [
            {"b": 1, "a0": 1},
        ]),
        ("ecall", "00000000000000000000000001110011", 2165, [
            {"cond": 0, "b": 1, "maddr": "csw_rt1", "excode": 2, "t11": 1, "c4": 1},
        ]),
        ("ebreak", "00000000000100000000000001110011", 2166, [
            {"b": 1, "a0": 1, "pause": 1},
        ]),
        ("mret", "00110000001000000000000001110011", 2167, [
            # TODO: revisar
            {"cond": 4, "maddr": 0, "excode": 0, "t11": 1, "c4": 1},
            {"mr": 1, "sela": 2, "t9": 1, "c0": 1},
            {"mr": 1, "sela": 2, "selc": 2, "mb": 0b10, "cop": 0b01010, "t6": 1, "lc": 1, "ta": 1},
            {"ta": 1, "r": 1, "m1": 1, "c1": 1, "bw": 0b11},
            {"t1": 1, "c7": 1},

            {"mr": 1, "sela": 2, "t9": 1, "c0": 1},
            {"mr": 1, "sela": 2, "selc": 2, "mb": 0b10, "cop": 0b01010, "t6": 1, "lc": 1, "ta": 1},
            {"ta": 1, "r": 1, "m1": 1, "c1": 1, "bw": 0b11},
            {"b": 1, "a0": 1, "t1": 1, "c2": 1},
        ]),
        # RV32Zmmul
        ("mul", "0000001----------000-----0110011", 2176, [
            {"b": 1, "a0": 1, "sela": 15, "selb": 20, "selc": 7, "cop": 0b01100, "t6": 1, "lc": 1},
        ]),
        ("mulh", "0000001----------001-----0110011", 2177, [
            {"b": 1, "a0": 1, "sela": 15, "selb": 20, "selc": 7, "cop": 0b11010, "t6": 1, "lc": 1},
        ]),
        ("mulhsu", "0000001----------010-----0110011", 2178, [
            {"b": 1, "a0": 1, "sela": 15, "selb": 20, "selc": 7, "cop": 0b11100, "t6": 1, "lc": 1},
        ]),
        ("mulhu", "0000001----------011-----0110011", 2179, [
            {"b": 1, "a0": 1, "sela": 15, "selb": 20, "selc": 7, "cop": 0b11011, "t6": 1, "lc": 1},
        ]),

        # Custom extensions
        ("in", "-------------------------0001011", 2180, [
            {"cond": 4, "maddr": 0, "excode": 0, "t11": 1, "c4": 1},
            {"size": 16, "offset": 16, "se": 0, "t3": 1, "c0": 1},
            {"ta": 1, "ior": 1, "m1": 1, "c1": 1},
            {"b": 1, "a0": 1, "selc": 7, "t1": 1, "lc": 1},
        ]),
        ("out", "-------------------------0101011", 2184, [
            {"cond": 4, "maddr": 0, "excode": 0, "t11": 1, "c4": 1},
            {"size": 16, "offset": 16, "se": 0, "t3": 1, "c0": 1},
            {"sela": 7, "t9": 1, "c1": 1},
            {"b": 1, "a0": 1, "iow": 1, "ta": 1, "td": 1},
        ]),
        ("illegal instruction", "--------------------------------", 2188, [
            {"cond": 0, "b": 1, "maddr": "csw_rt1", "excode": 0, "t11": 1, "c4": 1, "pause": 1},
        ]),
    ]  # fmt: skip
    microprograms = [MicroProgram(*x) for x in microprograms] + BOOTLOADER

    encodings = [
        Encoding(False, 32, []),
        Encoding(True, 0, [(31, 20)]),
        Encoding(True, 0, [(31, 25), (11, 7)]),
        Encoding(True, 1, [(31, 31), (7, 7), (30, 25), (11, 8)]),
        Encoding(True, 12, [(31, 12)]),
        Encoding(True, 1, [(31, 31), (19, 12), (20, 20), (30, 21)]),
    ]

    firmware = Firmware(encodings, microprograms, "little", 0b111110000000)
    print(firmware.gen())
