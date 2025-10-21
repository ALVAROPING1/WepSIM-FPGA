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

    bcddecoder = tests.test_bench("BCDDecoder_TB")
    for size in [1, 2, 3, 7, 8, 16, 20]:
        bcddecoder.add_config(name=f"size={size}", generics={"size": size})

    display7segment = tests.test_bench("Display7segment_TB")
    for size in [1, 2, 3, 7, 8, 16, 20]:
        display7segment.add_config(name=f"size={size}", generics={"size": size})

    tristate = tests.test_bench("Tristate_TB")
    for size in [1, 2, 3, 4]:
        tristate.add_config(name=f"size={size}", generics={"size": size})

    # ───────────────────────────────────── Main ─────────────────────────────────────

    vu.set_sim_option("nvc.sim_flags", ["--dump-arrays"])  # pyright: ignore

    # Run vunit function
    vu.main()
