# Milestone 4 (WIP)

TLDR: Improved simple CPU to be able to execute large portion RV64I base and verified its functionality with regression-style test program, assembled into memh and loaded into RAM.

---

## Changelog

### Core is now split into more modules

In MS3, most of the logic was in `core_mc.sv`. When adding more instructions for MS4, the file became unreadable, so it was split up into more files.

- `core_top.sv`
  - Wires together the other modules.
  - Exposes the unified bus master interface and debug outputs.

- `frontend.sv`
  - Has program counter and instruction register.
  - Implements instruction fetch over the unified bus using 64-bit aligned reads, then selects the low/high 32-bit instruction based on `PC[2]`.
  - Handshakes with the control FSM using `if_start/if_busy/if_done/if_err`, and accepts `pc_we/pc_next` updates after execute.

- `decoder.sv` (already present, major changes)
  - Splits the 32-bit instruction into standard fields (`opcode`, `rd`, `rs1`, `rs2`, `funct3`, `funct7`) and all immediates (`imm_i/s/b/u/j`).
  - Produces a single “op” struct `uop` that describes the kind of operation core should do (ALU op select, branch type, load/store size, writeback select, etc.)

- `riscv_pkg.sv`
  - Package that holds enums/structs used across the design.
  - Makes control logic much easier to read. Also stops decoder from being infinite lines long...
  - Key types:
    - `instr_kind_t` (ALU, LUI, JAL, BRANCH, SYSTEM, etc.)
    - `alu_op_t` (ADD, SUB, etc. Includes RV64 “W” ops)
    - `alua_sel_t`, `alub_sel_t` (operand selects)
    - `wb_sel_t` (writeback select)
    - `pc_sel_t` (PC select)
    - `mem_size_t` (memory size)
    - `dec_uop_t` (Main decoded bundle)

- `regfile.sv` (already present, no changes)
  - 32 x 64-bit integer regs.
  - x0 hardwired to 0 (reads return 0, writes ignored).
  - Combinational reads and synchronous write.

- `alu.sv` (already present, major changes)
  - Usual ALU operations (ADD, SUB, SLT, shifts, etc.).
  - RV64 “W” operations (ADDW/SLLW/etc.) by computing in 32-bit and sign-extending to 64.

- `exu.sv`
  - Computes ALU result based on `uop` operand selects.
  - Computes branch decisions for all 6 branch types and JALR target.

- `lsu.sv`
  - Handles loads/stores.
  - Supports byte/half/word/dword accesses:
    - Stores generate `wstrb` and shift store data to the correct byte.
    - Loads sign or zero extend based on instruction.
  - Detects misalignment (B/H/W/D rules) and returns an error.

- `control_fsm.sv`
  - The multi-cycle sequencer that joins everything together.
  - States:
    - IFETCH (fetch instruction) -> DECODE (get `uop`) -> MEM (optional LSU) -> EXEC (writeback + PC update) -> IFETCH.
  - Arbitrates the unified bus:
    - Frontend during IFETCH
    - LSU during MEM
  - SYSTEM instructions at the moment:
    - FENCE is treated as a legal NOP.
    - ECALL/EBREAK halts.

### Testing

- `sw/rv64_test.S`
  - Self-checking assembly program that branches to FAIL labels on mismatch.
  - PASS ends in `PASS: ebreak`.
  - Added Makefile to compile into hex to load into RAM

### Other Changes

- Added this milestone doc as well as others, changed old one to a summary

---

## Instructions currently supported

The current design passes a single regression-style test that checks:

### Integer ALU (OP / OP-IMM)

- ADD, SUB, AND, OR, XOR
- SLL, SRL, SRA
- SLT, SLTU
- ADDI, ANDI, ORI, XORI
- SLTI, SLTIU
- SLLI, SRLI, SRAI

### Upper immediates

- LUI, AUIPC

### Jumps/Branches

- JAL, JALR
- BEQ, BNE, BLT, BGE, BLTU, BGEU

### Loads/stores

- Stores: SB, SH, SW, SD
- Loads: LB, LBU, LH, LHU, LW, LWU, LD

### RV64 “W” ops (32-bit result sign-extended to 64)

- ADDIW
- SLLIW, SRLIW, SRAIW
- ADDW, SUBW, SLLW, SRLW, SRAW

### Notes

- `EBREAK` currently halts the CPU.
- `FENCE` currently treated as legal NOP.

---

## How to run

1) Assemble the test:
   - `make -C sw`
2) Run simulation with program load:
   - `make -C sim run`
3) View waveform:
   - `gtkwave sim/dump.vcd`
