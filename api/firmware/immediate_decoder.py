from dataclasses import dataclass
from typing import Final, Optional

WORD_SIZE: Final[int] = 32


@dataclass
class Encoding:
    sign_extend: bool
    padding: int
    ranges: list[tuple[int, int]]

    def to_vhdl(self, in_name: str) -> Optional[str]:
        if len(self.ranges) == 0:
            return None
        bits = sum(e - s + 1 for e, s in self.ranges) + self.padding
        if bits > WORD_SIZE:
            raise ValueError(
                f"Ranges select `{bits}` bits, but only {WORD_SIZE} are allowed"
            )
        ranges = [f"{in_name}({e} downto {s})" for e, s in self.ranges]
        if bits < WORD_SIZE:
            msb = self.ranges[0][0]
            extension = f"{in_name}({msb})" if self.sign_extend else "0"
            ranges.insert(0, f"({in_name}'high - {bits} downto 0 => {extension})")
        if self.padding > 0:
            ranges.append(f'"{"0" * self.padding}"')
        return " & ".join(ranges)


def decoder_gen(encodings: list[Encoding]) -> tuple[str, str]:
    cases = "\n".join(
        " " * 12 + f"when {i} => return {x};"
        for i, x in enumerate(x.to_vhdl("d_in") for x in encodings)
        if x is not None
    )

    return (
        """pure function immediate_decoder(id: natural; d_in: std_ulogic_vector)
        return std_ulogic_vector""",
        f"""is
    begin
        case id is
{cases}
            when others => return d_in;
        end case;
    end;""",
    )
