.section .text
.globl _start

_start:
    la      t0, trap_handler
    csrw    mtvec, t0

    # Sentinel value. An illegal CSR access must NOT overwrite s0.
    li      s0, 0x55

bad_csr:
    # CSR 0x999 is unsupported by your CSR file
    csrr    s0, 0x999

after_bad_csr:
    # Handler should have skipped the bad instruction
    li      t0, 0x55
    bne     s0, t0, fail

pass:
    j pass


trap_handler:
    # Must be illegal instruction
    csrr    t0, mcause
    li      t1, 2
    bne     t0, t1, fail

    # mepc must point at the offending CSR instruction
    csrr    t0, mepc
    la      t1, bad_csr
    bne     t0, t1, fail

    # s0 must still contain its old value:
    # the illegal CSR must not have committed its rd write
    li      t0, 0x55
    bne     s0, t0, fail

    # Skip bad CSR instruction
    csrr    t0, mepc
    addi    t0, t0, 4
    csrw    mepc, t0

    mret


fail:
    j fail
