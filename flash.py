import sys
from argparse import ArgumentParser
from pyfpga.vivado import Vivado

prj = Vivado("vhdl", odir="build")
prj.set_part("xc7a100tcsg324-1")
prj.add_vhdl("src/**/*.vhdl")
prj.add_cons("src/Nexys-A7-100T-Master.xdc")
prj.set_top("Cpu")
prj.add_param("size", "32")

prj.add_hook(
    "postcfg",
    "set_property file_type {VHDL 2019} [get_files -filter {FILE_TYPE == VHDL}]",
)
with open("clk_divider.tcl", "r") as f:
    prj.add_hook("postcfg", f.read())

if __name__ == "__main__":
    parser = ArgumentParser(exit_on_error=True)
    parser.add_argument(
        "--compile",
        "-c",
        default=False,
        required=False,
        help="Compile CPU to .bit file",
        action="store_true",
    )
    parser.add_argument(
        "--flash",
        "-f",
        default=False,
        required=False,
        help="Flash .bit file to FPGA",
        action="store_true",
    )
    args = parser.parse_args(sys.argv[1:])
    compile = args.compile
    flash = args.flash
    if not compile and not flash:
        compile = True
        flash = True
    if compile:
        prj.make()
    if flash:
        prj.prog()
