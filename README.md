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
