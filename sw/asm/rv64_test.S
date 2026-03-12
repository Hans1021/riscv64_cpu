    .option norvc
    .text
    .globl _start

/*
PASS/FAIL convention
- PASS ends at label pass: ebreak
- FAIL ends at label fail_N: ebreak
Use the halt PC and .dis to see which label
*/

    .macro FAIL num
        j fail_\num
    .endm

    .macro CHECK_EQ reg, exp, num
        bne \reg, \exp, fail_\num
    .endm

_start:
    fence

    # --------------------------------------------------------------------------
    # Basic setup
    # --------------------------------------------------------------------------
    li   x1, 5
    li   x2, 7

    # --------------------------------------------------------------------------
    # OP
    # --------------------------------------------------------------------------
    add  x3, x1, x2
    li   x4, 12
    CHECK_EQ x3, x4, 1

    sub  x3, x2, x1
    li   x4, 2
    CHECK_EQ x3, x4, 2

    and  x3, x1, x2
    li   x4, 5
    CHECK_EQ x3, x4, 3

    or   x3, x1, x2
    li   x4, 7
    CHECK_EQ x3, x4, 4

    xor  x3, x1, x2
    li   x4, 2
    CHECK_EQ x3, x4, 5

    li   x5, 1
    li   x6, 3
    sll  x3, x5, x6
    li   x4, 8
    CHECK_EQ x3, x4, 6

    li   x5, 32
    li   x6, 2
    srl  x3, x5, x6
    li   x4, 8
    CHECK_EQ x3, x4, 7

    li   x5, -8
    li   x6, 1
    sra  x3, x5, x6
    li   x4, -4
    CHECK_EQ x3, x4, 8

    li   x5, -1
    li   x6, 0
    slt  x3, x5, x6
    li   x4, 1
    CHECK_EQ x3, x4, 9

    sltu x3, x5, x6
    li   x4, 0
    CHECK_EQ x3, x4, 10

    # --------------------------------------------------------------------------
    # OP-IMM
    # --------------------------------------------------------------------------
    addi x3, x1, 9
    li   x4, 14
    CHECK_EQ x3, x4, 11

    andi x3, x2, 3
    li   x4, 3
    CHECK_EQ x3, x4, 12

    ori  x3, x0, 0x55
    li   x4, 0x55
    CHECK_EQ x3, x4, 13

    xori x3, x3, 0x0F
    li   x4, 0x5A
    CHECK_EQ x3, x4, 14

    li   x5, -1
    slti x3, x5, 0
    li   x4, 1
    CHECK_EQ x3, x4, 15

    sltiu x3, x5, 0
    li   x4, 0
    CHECK_EQ x3, x4, 16

    li   x5, 1
    slli x3, x5, 5
    li   x4, 32
    CHECK_EQ x3, x4, 17

    srli x3, x3, 2
    li   x4, 8
    CHECK_EQ x3, x4, 18

    li   x5, -8
    srai x3, x5, 1
    li   x4, -4
    CHECK_EQ x3, x4, 19

    # --------------------------------------------------------------------------
    # LUI / AUIPC
    # --------------------------------------------------------------------------
    lui  x3, 0x12345
    lui  x4, 0x12345
    CHECK_EQ x3, x4, 20

    auipc x6, 0
    auipc x7, 0
    addi  x6, x6, 4
    CHECK_EQ x6, x7, 21

    # --------------------------------------------------------------------------
    # Branches
    # --------------------------------------------------------------------------
    li   x3, 1
    li   x4, 1
    beq  x3, x4, 1f
    j    fail_22
1:
    li   x4, 2
    bne  x3, x4, 2f
    j    fail_23
2:
    li   x5, -1
    blt  x5, x0, 3f
    j    fail_24
3:
    bge  x0, x0, 4f
    j    fail_25
4:
    bltu x0, x5, 5f
    j    fail_26
5:
    bgeu x5, x0, 6f
    j    fail_27
6:

    # --------------------------------------------------------------------------
    # Loads / Stores
    # --------------------------------------------------------------------------
    la   x10, data

    li   x11, 0x1122334455667788
    sd   x11, 0(x10)
    ld   x13, 0(x10)
    CHECK_EQ x13, x11, 28

    li   x14, 0x80
    sb   x14, 8(x10)
    lb   x15, 8(x10)
    lbu  x16, 8(x10)
    li   x17, 0x80
    CHECK_EQ x16, x17, 29
    li   x17, -128
    CHECK_EQ x15, x17, 30

    li   x14, 0x801
    sh   x14, 10(x10)
    lh   x15, 10(x10)
    lhu  x16, 10(x10)
    li   x17, 0x801
    CHECK_EQ x16, x17, 31
    CHECK_EQ x15, x17, 32

    li   x14, 0x80000001
    sw   x14, 12(x10)
    lw   x15, 12(x10)
    lwu  x16, 12(x10)
    li   x17, 0x80000001
    CHECK_EQ x16, x17, 33
    li   x18, 0xFFFFFFFF80000001
    CHECK_EQ x15, x18, 34

    # --------------------------------------------------------------------------
    # JAL / JALR
    # --------------------------------------------------------------------------
    jal  x1, func
    li   x21, 0x5A
    CHECK_EQ x20, x21, 35

    # --------------------------------------------------------------------------
    # OP-IMM-32 / OP-32
    # --------------------------------------------------------------------------
    li   x22, -1
    addiw x23, x22, 1
    CHECK_EQ x23, x0, 36

    li   x22, 1
    slliw x23, x22, 31
    li   x24, 0xFFFFFFFF80000000
    CHECK_EQ x23, x24, 37

    srliw x25, x23, 31
    li    x26, 1
    CHECK_EQ x25, x26, 38

    sraiw x25, x23, 31
    li    x26, -1
    CHECK_EQ x25, x26, 39

    li   x22, 5
    li   x23, 7
    addw x24, x22, x23
    li   x26, 12
    CHECK_EQ x24, x26, 40

    subw x24, x23, x22
    li   x26, 2
    CHECK_EQ x24, x26, 41

    li   x22, 1
    li   x23, 33              # low 5 bits = 1
    sllw x24, x22, x23
    li   x26, 2
    CHECK_EQ x24, x26, 42

    srlw x24, x24, x23
    li   x26, 1
    CHECK_EQ x24, x26, 43

    li   x22, 0x80000000
    li   x26, 1
    sraw x24, x22, x26
    li   x27, 0xFFFFFFFFC0000000
    CHECK_EQ x24, x27, 44

    # --------------------------------------------------------------------------
    # RV64M
    # --------------------------------------------------------------------------

    # MUL
    li   x5, 6
    li   x6, 7
    mul  x3, x5, x6
    li   x4, 42
    CHECK_EQ x3, x4, 45

    # MULH: (-2 * 3) >> 64 = all ones in upper half
    li   x5, -2
    li   x6, 3
    mulh x3, x5, x6
    li   x4, -1
    CHECK_EQ x3, x4, 46

    # MULHU: (2^64-1) * 2 => high half = 1
    li   x5, -1
    li   x6, 2
    mulhu x3, x5, x6
    li    x4, 1
    CHECK_EQ x3, x4, 47

    # MULHSU: (-2) * 3 => high half = -1
    li   x5, -2
    li   x6, 3
    mulhsu x3, x5, x6
    li   x4, -1
    CHECK_EQ x3, x4, 48

    # DIV / DIVU
    li   x5, 20
    li   x6, 3
    div  x3, x5, x6
    li   x4, 6
    CHECK_EQ x3, x4, 49

    li   x5, -20
    li   x6, 3
    div  x3, x5, x6
    li   x4, -6
    CHECK_EQ x3, x4, 50

    li   x5, 20
    li   x6, 3
    divu x3, x5, x6
    li   x4, 6
    CHECK_EQ x3, x4, 51

    # REM / REMU
    li   x5, 20
    li   x6, 3
    rem  x3, x5, x6
    li   x4, 2
    CHECK_EQ x3, x4, 52

    li   x5, -20
    li   x6, 3
    rem  x3, x5, x6
    li   x4, -2
    CHECK_EQ x3, x4, 53

    li   x5, 20
    li   x6, 3
    remu x3, x5, x6
    li   x4, 2
    CHECK_EQ x3, x4, 54

    # divide by zero behavior
    li   x5, 123
    li   x6, 0
    div  x3, x5, x6
    li   x4, -1
    CHECK_EQ x3, x4, 55

    divu x3, x5, x6
    li   x4, -1
    CHECK_EQ x3, x4, 56

    rem  x3, x5, x6
    li   x4, 123
    CHECK_EQ x3, x4, 57

    remu x3, x5, x6
    li   x4, 123
    CHECK_EQ x3, x4, 58

    # signed overflow: INT64_MIN / -1 = INT64_MIN, rem = 0
    li   x5, 0x8000000000000000
    li   x6, -1
    div  x3, x5, x6
    CHECK_EQ x3, x5, 59

    rem  x3, x5, x6
    CHECK_EQ x3, x0, 60

    # MULW
    li   x5, 6
    li   x6, 7
    mulw x3, x5, x6
    li   x4, 42
    CHECK_EQ x3, x4, 61

    # 0x80000000 * 2 => low 32 bits = 0 => sign-extended 0
    li   x5, 0x80000000
    li   x6, 2
    mulw x3, x5, x6
    CHECK_EQ x3, x0, 62

    # DIVW / DIVUW
    li   x5, 20
    li   x6, 3
    divw x3, x5, x6
    li   x4, 6
    CHECK_EQ x3, x4, 63

    divuw x3, x5, x6
    li    x4, 6
    CHECK_EQ x3, x4, 64

    # REMW / REMUW
    remw  x3, x5, x6
    li    x4, 2
    CHECK_EQ x3, x4, 65

    remuw x3, x5, x6
    li    x4, 2
    CHECK_EQ x3, x4, 66

    # W divide by zero
    li   x5, 123
    li   x6, 0
    divw x3, x5, x6
    li   x4, -1
    CHECK_EQ x3, x4, 67

    divuw x3, x5, x6
    li    x4, -1
    CHECK_EQ x3, x4, 68

    remw x3, x5, x6
    li   x4, 123
    CHECK_EQ x3, x4, 69

    remuw x3, x5, x6
    li    x4, 123
    CHECK_EQ x3, x4, 70

    # W signed overflow: INT32_MIN / -1 = INT32_MIN, rem = 0
    li   x5, 0x80000000
    li   x6, -1
    divw x3, x5, x6
    li   x4, 0xFFFFFFFF80000000
    CHECK_EQ x3, x4, 71

    remw x3, x5, x6
    CHECK_EQ x3, x0, 72

pass:
    ebreak

func:
    li   x20, 0x5A
    jalr x0, 0(x1)

fail_1:   FAIL 1
fail_2:   FAIL 2
fail_3:   FAIL 3
fail_4:   FAIL 4
fail_5:   FAIL 5
fail_6:   FAIL 6
fail_7:   FAIL 7
fail_8:   FAIL 8
fail_9:   FAIL 9
fail_10:  FAIL 10
fail_11:  FAIL 11
fail_12:  FAIL 12
fail_13:  FAIL 13
fail_14:  FAIL 14
fail_15:  FAIL 15
fail_16:  FAIL 16
fail_17:  FAIL 17
fail_18:  FAIL 18
fail_19:  FAIL 19
fail_20:  FAIL 20
fail_21:  FAIL 21
fail_22:  FAIL 22
fail_23:  FAIL 23
fail_24:  FAIL 24
fail_25:  FAIL 25
fail_26:  FAIL 26
fail_27:  FAIL 27
fail_28:  FAIL 28
fail_29:  FAIL 29
fail_30:  FAIL 30
fail_31:  FAIL 31
fail_32:  FAIL 32
fail_33:  FAIL 33
fail_34:  FAIL 34
fail_35:  FAIL 35
fail_36:  FAIL 36
fail_37:  FAIL 37
fail_38:  FAIL 38
fail_39:  FAIL 39
fail_40:  FAIL 40
fail_41:  FAIL 41
fail_42:  FAIL 42
fail_43:  FAIL 43
fail_44:  FAIL 44
fail_45:  FAIL 45
fail_46:  FAIL 46
fail_47:  FAIL 47
fail_48:  FAIL 48
fail_49:  FAIL 49
fail_50:  FAIL 50
fail_51:  FAIL 51
fail_52:  FAIL 52
fail_53:  FAIL 53
fail_54:  FAIL 54
fail_55:  FAIL 55
fail_56:  FAIL 56
fail_57:  FAIL 57
fail_58:  FAIL 58
fail_59:  FAIL 59
fail_60:  FAIL 60
fail_61:  FAIL 61
fail_62:  FAIL 62
fail_63:  FAIL 63
fail_64:  FAIL 64
fail_65:  FAIL 65
fail_66:  FAIL 66
fail_67:  FAIL 67
fail_68:  FAIL 68
fail_69:  FAIL 69
fail_70:  FAIL 70
fail_71:  FAIL 71
fail_72:  FAIL 72

    .align 3
data:
    .dword 0
    .dword 0
    .dword 0
    .dword 0
