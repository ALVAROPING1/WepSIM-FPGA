from dataclasses import dataclass
from typing import Any

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
        microprograms = [MicroProgram(**x) for x in data["microprograms"]]
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
