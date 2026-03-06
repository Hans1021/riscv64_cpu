# Milestone 5: Runs C Bare-Metal on RV64 (Complete)

## Changelog

- `link.ld`
  - GNU ld linker script (ELF)
  - Places `.text`, `.rodata`, `.data`, `.bss` in RAM
  - Defines stack top and entry point
- `crt0.S`
  - Bare-metal startup
  - Sets stack pointer, calls main
- `main.c`
  - C test program that verifies some CPU behavior
    - Weak for testing each instruction, more to demonstrate C can run
  - Fence NOP at PASS for signal
- `README.md`
  - Project description

- `Makefile`, `ci.yml` for builds and running + minor RTL and doc fixes

## How to run

1) Build and run CPU tests:
    - `make`
2) View waveform:
    - `gtkwave sim/dump.vcd`
