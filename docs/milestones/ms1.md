# Milestone 1: Smoke Sim (Complete)

## Added

- `top.sv`
  - Simple sequential counter to verifying clocking and reset
- `main.cpp` testbench
  - Toggles clock and reset
  - dumps `dump.vdc` to check with GTKWave
- CI
  - GitHub Action job installs Verilator and compiler
- Runs smoke test

## How to run

- Build and run:
  - `make -C sim run`
- View waveform:
  - `gtkwave sim/sump.vcd`
