# Milestone 6: M Extension (done), more? (WIP)

TLDR: M extension implemented, more to be done

## Changelog

- `muldiv.sv`
  - New module for the M extension
  - Supports `MUL, MULH, MULHU, MULHSU, DIV, DIVU, REM, REMU`
  - Plus W ops `MULW, DIVW, DIVUW, REMW, REMUW`
- `riscv_pkg.sv`
  - Made some simplifications and readability changes
    - System ops has its own type
  - Added type for muldiv ops
- `exu.sv`
  - Instantiates muldiv module and works with new muldiv operations
- `decoder.sv`
  - Instruction decode for M extension
  - Fixed an unnoticed bug for `SLLI`, `SLRI`, and `SRAI`:
    - Decoding by requiring `funct7_i == 7'b0000000` was too strict by 1 bit
    - Should just be legal when `inst_i[31:26] == 6'b000000`
- `rv64_test.S`
  - ISA tests in assembly, contains every instruction so far
  - `EBREAK` on pass, jump in place on fails
    - Much easier to debug
- `main.c`
  - C program made much simpler just for demonstration, since ISA testing is back to using assembly

- `Makefile`, `ci.yml` for builds and running + other RTL and doc fixes

## How to run

1) Build and run:
    - `make asm` for ISA test with assembly **OR**
    - `make c` for bare-metal C demonstration
2) View waveform:
    - `gtkwave sim/dump.vcd`
