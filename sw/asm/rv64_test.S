.section .text
.globl _start

_start:
    # CSRRWI: mscratch = 3
    csrrwi  x0, mscratch, 3

    # Read back
    csrr    t0, mscratch
    li      t1, 3
    bne     t0, t1, fail

    # CSRRSI: set bit 2
    csrrsi  x0, mscratch, 4

    csrr    t0, mscratch
    li      t1, 7
    bne     t0, t1, fail

    # CSRRCI: clear bit 1
    csrrci  x0, mscratch, 2

    csrr    t0, mscratch
    li      t1, 5
    bne     t0, t1, fail

pass:
    j pass

fail:
    j fail