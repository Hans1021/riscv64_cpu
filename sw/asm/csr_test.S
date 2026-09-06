.section .text
.globl _start

_start:
    # CSRRW
    li      t0, 0x123
    csrw    mscratch, t0

    csrr    t1, mscratch
    li      t2, 0x123
    bne     t1, t2, fail

    # CSRRS
    li      t0, 4
    csrs    mscratch, t0

    csrr    t1, mscratch
    li      t2, 0x127
    bne     t1, t2, fail

    # CSRRC
    li      t0, 2
    csrc    mscratch, t0

    csrr    t1, mscratch
    li      t2, 0x125
    bne     t1, t2, fail

    # Immediate forms
    csrrwi  x0, mscratch, 3
    csrrsi  x0, mscratch, 4
    csrrci  x0, mscratch, 2

    csrr    t1, mscratch
    li      t2, 5
    bne     t1, t2, fail

pass:
    j pass

fail:
    j fail
    