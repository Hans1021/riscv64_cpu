.section .text
.globl _start

_start:
    la      t0, trap_handler
    csrw    mtvec, t0

    li      s0, 0

    # Test ECALL
ecall_inst:
    ecall

after_ecall:
    li      t0, 1
    bne     s0, t0, fail

    # Test EBREAK
ebreak_inst:
    ebreak

after_ebreak:
    li      t0, 2
    bne     s0, t0, fail

    # Test illegal instruction
illegal_inst:
    .word   0xffffffff

after_illegal:
    li      t0, 3
    bne     s0, t0, fail

pass:
    j pass


trap_handler:
    csrr    t0, mcause

    # ECALL
    li      t1, 11
    beq     t0, t1, handle_ecall

    # EBREAK
    li      t1, 3
    beq     t0, t1, handle_ebreak

    # Illegal instruction
    li      t1, 2
    beq     t0, t1, handle_illegal

    j       fail


handle_ecall:
    li      s0, 1
    j       return_from_trap

handle_ebreak:
    li      s0, 2
    j       return_from_trap

handle_illegal:
    # mtval should contain 0x00000000ffffffff
    csrr    t2, mtval
    li      t3, 0xffffffff
    bne     t2, t3, fail

    li      s0, 3


return_from_trap:
    # Skip faulting instruction
    csrr    t0, mepc
    addi    t0, t0, 4
    csrw    mepc, t0
    mret


fail:
    j fail
