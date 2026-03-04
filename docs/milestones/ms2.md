# Milestone 2: SoC + RAM (Complete)

## Added
- `memory_map.md`
    - RAM base and size
    - Reserved MMIO regions
    - Reset PC location
- `bus_spec.md`
    - Request and response channels
    - Handshake rules
    - Single outstanding request assumption
    - Alignment rules and error behavior
- `ram.sv`
    - 64-bit word-addressed RAM
    - byte enables (`wstrb`)
- `soc.sv`
    - Address decode and response mux
    - Forwards RAM accesses to `ram.sv`
    - Unmapped accesses return error

## Changes
- C++ bus tests
    - `main.cpp` drives the bus directly
    - Checks 64-bit read/write
    - byte-enabled write
    - error response

## How to run
- Build and run:
    - `make -C sim run`
- View waveform:
    - `gtkwave sim/sump.vcd`