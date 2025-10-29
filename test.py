from itertools import repeat
from typing import Sequence
from vunit import VUnit
from os import environ


if __name__ == "__main__":
    # Set VUnit simulator to NVC via env var (needed if GHDL is also installed)
    sim_var = "VUNIT_SIMULATOR"
    if environ.get(sim_var) is None:
        environ[sim_var] = "nvc"

    # ──────────────────────────────────── Setup ──────────────────────────────────

    # Create VUnit instance by parsing command line arguments
    vu = VUnit.from_argv(compile_builtins=False)
    # Add VUnit's builtin HDL utilities. SEE: http://vunit.github.io/hdl_libraries.html.
    vu.add_vhdl_builtins()
    vu.add_osvvm()
    vu.enable_check_preprocessing()
    vu.enable_location_preprocessing()

    # ────────────────────────────────── Libraries ────────────────────────────────

    # Create library 'src' and add all files ending in .vhdl from src to library
    vu.add_library("src").add_source_files("src/*.vhdl")
    # Create library 'tests' and add all files ending in .vhdl from tests to library
    tests = vu.add_library("tests")
    tests.add_source_files("tests/*.vhdl")

    # ──────────────────────────────────── Tests ──────────────────────────────────

    def generic_test(tb_name: str, names: list[str], cases: Sequence[list[int] | int]):
        tb = tests.test_bench(tb_name)
        for case in cases:
            case = case if isinstance(case, list) else repeat(case)
            generics = {k: v for k, v in zip(names, case)}
            name = ",".join(f"{k}={v}" for k, v in generics.items())
            tb.add_config(name=name, generics=generics)

    generic_test("BCDDecoder_TB", ["size"], [1, 4, 7, 8, 20])
    generic_test("Display7segment_TB", ["size"], [1, 2, 3, 8, 20])
    generic_test("TriState_TB", ["size"], [1, 2, 3, 4])
    generic_test("Reg_TB", ["size"], [1, 2, 4, 8, 16])
    mux_cases = [[1, 2], [1, 4], [3, 2], [3, 8]]
    generic_test("Multiplexer_TB", ["size", "addresses"], mux_cases)
    generic_test("Demultiplexer_TB", ["size", "addresses"], mux_cases)
    generic_test(
        "RAM_TB",
        ["size", "addresses"],
        [[1, 2], [1, 4], [8, 16], [8, 256], [32, 2**14]],
    )
    generic_test(
        "RegisterFile_TB",
        ["size", "addresses", "read_outputs"],
        [[1, 2, 1], [2, 4, 2], [8, 32, 2], [32, 32, 8], [64, 64, 16], [1024, 128, 16]],
    )
    # vhdl only guarantees up to 32 bit ints, so we can't go higher than that
    generic_test("Adder_TB", ["size"], [4, 8, 16, 24, 31])
    generic_test("Multiplier_TB", ["size"], [4, 8, 16])

    # ───────────────────────────────────── Main ─────────────────────────────────────

    vu.set_sim_option("nvc.sim_flags", ["--dump-arrays"])  # pyright: ignore

    # Run vunit function
    vu.main()
