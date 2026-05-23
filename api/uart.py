import sys
from dataclasses import dataclass

import serial

WORD_SIZE = 4

uart = serial.Serial(baudrate=1500000, rtscts=True)


@dataclass
class Segment:
    addr: int
    data: bytearray


def process_data(data: dict[int, str]) -> list[Segment]:
    segments: list[Segment] = []
    curr_addr = None
    for addr, value in sorted(data.items(), key=lambda x: x[0]):
        if curr_addr is None or addr != curr_addr:
            segments.append(Segment(addr, bytearray()))
            curr_addr = addr
        for i in range(len(value), 0, -8):
            byte = int(value[max(i - 8, 0) : i], 2)
            segments[-1].data.append(byte)
            curr_addr += 1
    return segments


def build_msg(ram: list[Segment], entrypoint: int) -> bytes:
    def format_word(x: int) -> bytes:
        res = bytearray()
        for _ in range(4):
            res.append(x & 0xFF)
            x = x >> 8
        return bytes(res)

    msg = bytearray()
    for segment in ram:
        msg.extend(format_word(segment.addr))  # Address
        msg.extend(format_word(len(segment.data) // WORD_SIZE))  # Size
        msg.extend(segment.data)  # Data
    # Stop markers
    msg.extend(format_word(0))
    msg.extend(format_word(0))
    msg.extend(format_word(entrypoint))
    return bytes(msg)


def flash_ram(msg: bytes):
    with uart as con:
        con.write(msg)


def key_description(character: str):
    return f"Ctrl+{chr(ord('@') + ord(character))}"


def terminal():
    from serial.tools.miniterm import Miniterm

    with uart as con:
        term = Miniterm(con, eol="lf")
        term.exit_character = "\x03"  # Ctrl+C
        term.menu_character = "\x01"  # Ctrl+A
        term.set_rx_encoding("UTF-8")
        term.set_tx_encoding("UTF-8")
        sys.stderr.write(
            f"--- Miniterm on {uart.name}  {uart.baudrate},{uart.bytesize},{uart.parity},{uart.stopbits} ---\n"
        )
        sys.stderr.write(
            "--- Quit: {} | Menu: {} | Help: {} followed by {} ---\n".format(
                key_description(term.exit_character),
                key_description(term.menu_character),
                key_description(term.menu_character),
                key_description("\x08"),
            )
        )

        term.start()
        try:
            term.join(True)
        except KeyboardInterrupt:
            pass
        term.join()
        term.close()


def flash_program(data: dict[int, str], entrypoint: int, port: str):
    uart.port = port or "/dev/ttyUSB1"
    ram = process_data(data)
    msg = build_msg(ram, entrypoint)
    flash_ram(msg)
    terminal()
