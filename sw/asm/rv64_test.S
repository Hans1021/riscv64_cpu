.section .text
.globl _start

_start:
    # Install trap handler
    la      t0, trap_handler
    csrw    mtvec, t0

    # Deliberately invalid instruction
    .word   0xffffffff

after_bad:
    # We should return here after the handler
    j pass


trap_handler:
    # mcause should be 2 = illegal instruction
    csrr    t0, mcause
    li      t1, 2
    bne     t0, t1, fail

    # mtval should contain the zero-extended offending instruction
    csrr    t0, mtval
    li      t1, 0xffffffff
    bne     t0, t1, fail

    # Skip over the illegal instruction
    csrr    t0, mepc
    addi    t0, t0, 4
    csrw    mepc, t0

    mret


pass:
    j pass

fail:
    j fail