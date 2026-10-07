# WepSIM-FPGA

Implementation of [WepSIM's](https://wepsim.github.io) Elemental
Processor on an FPGA. This project was developed with a Nexys A7-100T
FPGA. While it should be able to work on other FPGAs, some things might
need to be manually adapted (such as the device's IO connections in `src/constraints.xdc`).

## Running

### Requirements

- Docker and Docker compose
- A Docker image of Vivado, which can be generated with [vivado-docker-minimal](https://github.com/ALVAROPING1/vivado-docker-minimal)

### Execution

The Docker container image can be generated with `docker compose build`.
Afterwards, the local server can be opened using `docker compose run --rm server`.

> [!IMPORTANT]
> The server should be opened after the FPGA is connected to the PC.
> Otherwise, it won't be picked up by Docker and flashing it might fail.

## Tests

Unit tests are run with [uv](https://docs.astral.sh/uv/) and [VUnit](https://vunit.github.io/),
using a VHDL compiler and simulator. For this, [nvc](https://github.com/nickg/nvc) is recommended.
All tests can be run at once with:

```bash
uv run test.py -p 0
```

The list of all tests can be obtained with:

```bash
uv run test.py --list
```

To run only a specific group of tests, a filter can be appended at the end using `*` wildcards:

```bash
uv run test.py -p 0 "*<entityname>*"
```

To debug a unit test, a waveform file can be exported and opened on a viewer like [surfer](https://gitlab.com/surfer-project/surfer):

```bash
uv run test.py --gui "*<entityname>_tb[.<generic-params>].<testname>"
```

## Project structure

- `api/`: Modules for bridging WepSIM, Vivado, and generating the VHDL firmware module based on WepSIM's firmware configuration
- `src/`: VHDL source files
  - `circuits/`: Implementation of complex logic circuits, formed by connecting primitive components together
  - `devices/`: Implementation of IO devices
  - `firmware/`: Definition of firmware configuration
  - `primitives/`: Implementation of primitive logic components
  - `clk_divider.tcl`: Script to generate the analog clock divider in Vivado for the system clock
  - `constraints.xdc`: Mapping of inputs/outputs of the circuit to FPGA pins
  - `main.vhdl`: Top level element of the circuit
- `tests/`: VHDL test benches for each of the components, using the same structure as `src/`
- `riscv.wepsim`: WepSIM firmware code implementing RISC-V's RV32I+Zmmul instructions
- `server.py`: Entry point for WepSIM's REST server
- `test.py`: Entry point for unit tests execution
