from itertools import repeat
from typing import Sequence, TypeAlias
from vunit.ui import VUnit
from os import environ

V: TypeAlias = int | str

if __name__ == "__main__":
    # Set VUnit simulator to NVC via env var (needed if GHDL is also installed)
    sim_var = "VUNIT_SIMULATOR"
    if environ.get(sim_var) is None:
        environ[sim_var] = "nvc"

    # ──────────────────────────────────── Setup ──────────────────────────────────

    # Create VUnit instance by parsing command line arguments
    vu = VUnit.from_argv(vhdl_standard="2019")
    # Add VUnit's builtin HDL utilities. SEE: http://vunit.github.io/hdl_libraries.html.
    vu.add_vhdl_builtins()
    vu.add_osvvm()

    # ────────────────────────────────── Libraries ────────────────────────────────

    # Create library 'src' and add all files ending in .vhdl from src to library
    vu.add_library("src").add_source_files("src/**/*.vhdl")
    # Create library 'tests' and add all files ending in .vhdl from tests to library
    tests = vu.add_library("tests")
    tests.add_source_files("tests/**/*.vhdl")

    # ──────────────────────────────────── Tests ──────────────────────────────────

    def generic_test(tb_name: str, names: list[str], cases: Sequence[Sequence[V] | V]):
        tb = tests.test_bench(tb_name)
        for case in cases:
            case = case if isinstance(case, list) else repeat(case)
            generics = {k: v for k, v in zip(names, case)}
            name = ",".join(f"{k}={v}" for k, v in generics.items())
            tb.add_config(name=name, generics=generics)

    generic_test("BCDDecoder_TB", ["size"], [1, 4, 7, 8, 20])
    generic_test("SegmentDisplayController_TB", ["digits"], [1, 2, 3, 8, 20])
    generic_test("TriState_TB", ["size"], [1, 2, 3, 4])
    generic_test("Reg_TB", ["size"], [1, 2, 4, 8, 16])
    mux_cases = [[1, 1], [1, 2], [3, 1], [3, 3]]
    generic_test("Multiplexer_TB", ["size", "addr_size"], mux_cases)
    generic_test("Demultiplexer_TB", ["size", "addr_size"], mux_cases)
    generic_test(
        "Source_TB",
        ["size", "value"],
        [[1, 0], [2, 3], [4, 3], [4, 4], [4, 8], [8, 32], [8, 255]],
    )
    generic_test(
        "RAM_TB",
        ["size", "addr_size"],
        [[4, 3], [4, 5], [8, 3], [16, 6], [16, 10], [32, 16]],
    )
    generic_test(
        "RegisterFile_TB",
        ["size", "addr_size", "read_outputs"],
        [[1, 1, 1], [2, 2, 2], [8, 5, 2], [32, 5, 8], [64, 6, 16], [1024, 7, 16]],
    )
    generic_test("Boolean_TB", ["size"], [2, 3, 4, 8, 32, 64, 512])
    generic_test("BooleanBinary_TB", ["size"], [2, 3, 4, 8, 32, 64, 512])
    generic_test(
        "Slicer_TB",
        ["offset_size", "out_size"],
        [[1, 1], [2, 1], [4, 1], [4, 8], [5, 5]],
    )
    generic_test("EdgeDetector_TB", ["edge"], ["'1'", "'0'"])
    # vhdl only guarantees up to 32 bit ints, so we can't go higher than that
    generic_test("Adder_TB", ["size"], [4, 8, 16, 24, 31])
    generic_test("Multiplier_TB", ["size"], [4, 8, 16])

    generic_test("MemoryMappedReg_TB", ["size"], [1, 2, 4, 8, 16, 32])
    generic_test("Timer_TB", ["size"], [4, 8, 16])

    # ───────────────────────────────────── Main ─────────────────────────────────────

    vu.set_sim_option("nvc.sim_flags", ["--dump-arrays"])  # pyright: ignore

    # Run vunit function
    vu.main()
