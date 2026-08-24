.section .text
.globl _start

_start:
    # Write 0x123 to mscratch
    li      t0, 0x123
    csrw    mscratch, t0

    # Read it back
    csrr    t1, mscratch

    # Compare against expected value
    li      t2, 0x123
    bne     t1, t2, fail

pass:
    j pass

fail:
    j fail