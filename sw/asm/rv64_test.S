.section .text
.globl _start

_start:
    # Set trap handler address
    la      t0, trap_handler
    csrw    mtvec, t0

    li      s0, 0

    # Trigger trap
    ecall

after_ecall:
    # Handler should have changed s0 to 1
    li      t0, 1
    bne     s0, t0, fail

pass:
    j pass


trap_handler:
    # Check mcause == 11 for ECALL
    csrr    t0, mcause
    li      t1, 11
    bne     t0, t1, fail

    # Check mtval == 0
    csrr    t0, mtval
    bnez    t0, fail

    # Confirm handler ran
    li      s0, 1

    # mepc points to the ECALL itself.
    # Skip over it before returning.
    csrr    t0, mepc
    addi    t0, t0, 4
    csrw    mepc, t0

    mret


fail:
    j fail