# Milestone 3: Multi-cycle RV64 Core Skeleton (Complete)

TLDR: Multi-cycle CPU is alive, can execute `ADDI`, `JAL`, `EBREAK` (which halts). Tests with simple hex program loaded into RAM.

## Added

- `regfile.sv`
  - 32x64-bit integer registers
  - x0 hardwired to 0, writes ignored
  - 2 read ports
  - 1 write port
- `alu.sv`
  - Only supports ADD currently
- `decoder.sv`
  - Extracts instruction fields
  - Compute i-type and j-type immediates
  - Decodes instructions for `ADDI`, `JAL`, `EBREAK`
- `core_mc.sv`
  - multi-cycle FSM:
    - fetch request
    - fetch response, latches instruction
    - decode
    - execute
  - Instruction fetch uses 64-bit aligned bus reads and selects low/high half for 32-bit instruction using `PC[2]`
  - `EBREAK` currently halts
- Program loading
  - Added memory loading via `+mem=` with `$readmemh()` in `ram.sv`
  - Created `m3_prog.hex`, a 4-insturction simple hex program to test

## Changes

- C++ bus tests
  - `main.cpp` no longer drives the bus
  - Simply ticks the CPU
  - Runs until `EBREAK` executes which halts, or a timeout
  - Added hex program location to `Makefile`

## How to run

- Build and run:
  - `make -C sim run`
- View waveform:
  - `gtkwave sim/sump.vcd`
