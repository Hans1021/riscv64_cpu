# RV64 Multi-Cycle CPU

A **RV64 RISC-V multi-cycle CPU written in SystemVerilog**, simulated with **Verilator**, currently capable of running **bare-metal C programs**.

The project is developed incrementally.

## Current Status

The CPU currently:

- Implements **RV64I base ISA**
- Uses a **multi-cycle architecture**
- Boots and executes **bare-metal C programs**

Development progress is tracked in milestone documents.

## Requirements

Required tools:

- Verilator
- RISC-V GCC toolchain
- make
- g++
- GTKWave (optional)

## Running the Simulation

`make run`

- Builds the software program
- Generates a memory image
- Runs the Verilator simuilation
- Loads the program into RAM

Use `gtkwave sim/dump.vcd` to view waveforms.

## Current ISA Support

### ALU

#### Registers

`ADD SUB AND OR XOR`
`SLL SRL SRA`
`SLT SLTU`

#### Immediates

`ADDI ANDI ORI XORI`
`SLTI SLTIU`
`SLLI SRLI SRAI`

#### RV64 W-Instructions

`ADDIW`
`ADDW SUBQ`
`SLLIW SRLIW SRAIW`
`SLLW SRLW SRAW`

### Loads / Stores

`LB LBU LH LHU LW LWU LD`
`SB SH SW SD`

### Control Flow

`JAL JALR`
`BEQ BNE`
`BLT BGE`
`BLTU BGEU`

### System

`EBREAK`
`ECALL`
`FENCE`
`FENCE.I`

## Milestones

See `docs/` for detailed descriptions

- Milestone 0: Project setup
- Milestone 1: Smoke simulation
- Milestone 2: SoC + RAM
- Milestone 3: Multi-cycle CPU skeleton
- Milestone 4: RV64I implementation
- Milestone 5: Run bare-metal C

## Design Overview

The CPU uses a multi-cycle architecture:

`FETCH->DECODE->EXECUTE->MEMORY->WRITEBACK`

- Single unified bus for instruction fetch and memory operations

## Future Work

- RV64 extensions
- Privileged ISA
- FPGA
- Pipelining
