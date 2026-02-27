    .option norvc
    .text
    .globl _start

/* PASS/FAIL method:
   Each check branches to a unique FAIL_n label.
   PASS ends at PASS: ebreak
*/

_start:
    fence

    # ---------- Basic setup ----------
    addi x1, x0, 5
    addi x2, x0, 7

    # ---------- OP ----------
    add  x3, x1, x2          # 12
    addi x4, x0, 12
    bne  x3, x4, FAIL_1

    sub  x3, x2, x1          # 2
    addi x4, x0, 2
    bne  x3, x4, FAIL_2

    and  x3, x1, x2          # 5
    addi x4, x0, 5
    bne  x3, x4, FAIL_3

    or   x3, x1, x2          # 7
    addi x4, x0, 7
    bne  x3, x4, FAIL_4

    xor  x3, x1, x2          # 2
    addi x4, x0, 2
    bne  x3, x4, FAIL_5

    # shifts with small known amounts
    addi x5, x0, 1
    addi x6, x0, 3
    sll  x3, x5, x6          # 8
    addi x4, x0, 8
    bne  x3, x4, FAIL_6

    addi x5, x0, 32
    addi x6, x0, 2
    srl  x3, x5, x6          # 8
    addi x4, x0, 8
    bne  x3, x4, FAIL_7

    addi x5, x0, -8
    addi x6, x0, 1
    sra  x3, x5, x6          # -4
    addi x4, x0, -4
    bne  x3, x4, FAIL_8

    # slt / sltu
    addi x5, x0, -1
    addi x6, x0, 0
    slt  x3, x5, x6          # 1
    addi x4, x0, 1
    bne  x3, x4, FAIL_9

    sltu x3, x5, x6          # 0
    addi x4, x0, 0
    bne  x3, x4, FAIL_10

    # ---------- OP-IMM ----------
    addi x3, x1, 9           # 14
    addi x4, x0, 14
    bne  x3, x4, FAIL_11

    andi x3, x2, 3           # 3
    addi x4, x0, 3
    bne  x3, x4, FAIL_12

    ori  x3, x0, 0x55
    addi x4, x0, 0x55
    bne  x3, x4, FAIL_13

    xori x3, x3, 0x0F        # 0x5A
    addi x4, x0, 0x5A
    bne  x3, x4, FAIL_14

    addi x5, x0, -1
    slti x3, x5, 0           # 1
    addi x4, x0, 1
    bne  x3, x4, FAIL_15

    sltiu x3, x5, 0          # 0
    addi x4, x0, 0
    bne  x3, x4, FAIL_16

    addi x5, x0, 1
    slli x3, x5, 5           # 32
    addi x4, x0, 32
    bne  x3, x4, FAIL_17

    srli x3, x3, 2           # 8
    addi x4, x0, 8
    bne  x3, x4, FAIL_18

    addi x5, x0, -8
    srai x3, x5, 1           # -4
    addi x4, x0, -4
    bne  x3, x4, FAIL_19

    # ---------- LUI / AUIPC ----------
    lui  x3, 0x12345
    lui  x4, 0x12345
    bne  x3, x4, FAIL_20

    auipc x6, 0
    auipc x7, 0
    addi  x6, x6, 4
    bne   x6, x7, FAIL_21

    # ---------- Branches ----------
    addi x3, x0, 1
    addi x4, x0, 1
    beq  x3, x4, 1f
    jal  x0, FAIL_22
1:
    addi x4, x0, 2
    bne  x3, x4, 2f
    jal  x0, FAIL_23
2:
    addi x5, x0, -1
    blt  x5, x0, 3f
    jal  x0, FAIL_24
3:
    bge  x0, x0, 4f
    jal  x0, FAIL_25
4:
    bltu x0, x5, 5f
    jal  x0, FAIL_26
5:
    bgeu x5, x0, 6f
    jal  x0, FAIL_27
6:

    # ---------- Loads/Stores ----------
    # x10 = &data
    la   x10, data

    # Build 64-bit pattern: 0x1122334455667788
    li   x11, 0x1122334455667788
    sd   x11, 0(x10)
    ld   x13, 0(x10)
    bne  x13, x11, FAIL_28

    # byte sign/zero extension
    addi x14, x0, 0x80
    sb   x14, 8(x10)
    lb   x15, 8(x10)
    lbu  x16, 8(x10)
    addi x17, x0, 0x80
    bne  x16, x17, FAIL_29
    addi x17, x0, -128
    bne  x15, x17, FAIL_30

    # halfword sign/zero extension: store 0x0801
    li   x14, 0x801
    sh   x14, 10(x10)
    lh   x15, 10(x10)
    lhu  x16, 10(x10)
    li   x17, 0x801
    bne  x16, x17, FAIL_31

    # word sign/zero extension: store 0x80000001
    li   x14, 0x80000001
    sw   x14, 12(x10)
    lw   x15, 12(x10)
    lwu  x16, 12(x10)

    # expected lwu = 0x0000000080000001
    li   x17, 0x80000001
    bne  x16, x17, FAIL_32

    # expected lw = 0xFFFFFFFF80000001
    li   x19, 0xFFFFFFFF80000001
    bne  x15, x19, FAIL_33

    # ---------- JAL / JALR ----------
    jal  x1, func
    addi x21, x0, 0x5A
    bne  x20, x21, FAIL_34

    # ---------- OP-IMM-32 / OP-32 ----------
    li   x22, -1
    addiw x23, x22, 1
    bne  x23, x0, FAIL_35

    # SLLIW: 1<<31 => 0x80000000 sign-extended => 0xFFFFFFFF80000000
    li   x22, 1
    slliw x23, x22, 31
    li   x24, 0xFFFFFFFF80000000
    bne  x23, x24, FAIL_36

    srliw x25, x23, 31       # => 1
    addi  x26, x0, 1
    bne   x25, x26, FAIL_37

    sraiw x25, x23, 31       # => -1
    li    x26, -1
    bne   x25, x26, FAIL_38

    # ADDW/SUBW
    addi x22, x0, 5
    addi x23, x0, 7
    addw x24, x22, x23
    addi x26, x0, 12
    bne  x24, x26, FAIL_39

    subw x24, x23, x22
    addi x26, x0, 2
    bne  x24, x26, FAIL_40

    # SLLW/SRLW: shift amount uses low 5 bits
    addi x22, x0, 1
    addi x23, x0, 33         # 33 -> 1
    sllw x24, x22, x23       # => 2
    addi x26, x0, 2
    bne  x24, x26, FAIL_41

    srlw x24, x24, x23       # 2 >> 1 => 1
    addi x26, x0, 1
    bne  x24, x26, FAIL_42

    # SRAW: -2^31 >> 1 => -2^30 = 0xFFFFFFFFC0000000
    li   x22, 0x80000000
    sraw x24, x22, x26
    li   x27, 0xFFFFFFFFC0000000
    bne  x24, x27, FAIL_43

PASS:
    ebreak

func:
    addi x20, x0, 0x5A
    jalr x0, 0(x1)

FAIL_1:  ebreak
FAIL_2:  ebreak
FAIL_3:  ebreak
FAIL_4:  ebreak
FAIL_5:  ebreak
FAIL_6:  ebreak
FAIL_7:  ebreak
FAIL_8:  ebreak
FAIL_9:  ebreak
FAIL_10: ebreak
FAIL_11: ebreak
FAIL_12: ebreak
FAIL_13: ebreak
FAIL_14: ebreak
FAIL_15: ebreak
FAIL_16: ebreak
FAIL_17: ebreak
FAIL_18: ebreak
FAIL_19: ebreak
FAIL_20: ebreak
FAIL_21: ebreak
FAIL_22: ebreak
FAIL_23: ebreak
FAIL_24: ebreak
FAIL_25: ebreak
FAIL_26: ebreak
FAIL_27: ebreak
FAIL_28: ebreak
FAIL_29: ebreak
FAIL_30: ebreak
FAIL_31: ebreak
FAIL_32: ebreak
FAIL_33: ebreak
FAIL_34: ebreak
FAIL_35: ebreak
FAIL_36: ebreak
FAIL_37: ebreak
FAIL_38: ebreak
FAIL_39: ebreak
FAIL_40: ebreak
FAIL_41: ebreak
FAIL_42: ebreak
FAIL_43: ebreak

    .align 3
data:
    .dword 0
    .dword 0
    .dword 0
    .dword 0