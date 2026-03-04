# ISA Target

- Target ISA: RV64I


## Current Instructions

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

- SB, SH, SW, SD
- LB, LBU, LH, LHU, LW, LWU, LD

### RV64 “W” ops (32-bit result sign-extended to 64)

- ADDIW
- SLLIW, SRLIW, SRAIW
- ADDW, SUBW
- SLLW, SRLW, SRAW

### System

- EBREAK
- ECALL
- FENCE

Notes:

- `EBREAK` currently halts, need to become breakpoint exception later.
