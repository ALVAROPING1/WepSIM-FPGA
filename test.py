from vunit import VUnit
from os import environ

from vunit.ui.library import Library

def generic_test(tests: Library, tb_name: str, sizes: list[int]):
    tb = tests.test_bench(tb_name)
    for size in sizes:
        tb.add_config(name=f"size={size}", generics={"size": size})


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

    generic_test(tests, "BCDDecoder_TB", [1, 4, 7, 8, 20])
    generic_test(tests, "Display7segment_TB", [1, 2, 3, 8, 20])
    generic_test(tests, "TriState_TB", [1, 2, 3, 4])

    # ───────────────────────────────────── Main ─────────────────────────────────────

    vu.set_sim_option("nvc.sim_flags", ["--dump-arrays"])  # pyright: ignore

    # Run vunit function
    vu.main()
