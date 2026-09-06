.section .text
.globl _start

_start:
    la      t0, trap_handler
    csrw    mtvec, t0

    # Set MIE = 1
    csrrsi  x0, mstatus, 8

    # Confirm MIE is actually set before the trap
    csrr    t0, mstatus
    andi    t0, t0, 8
    beqz    t0, fail

trap_inst:
    ecall

after_trap:
    # After MRET:
    # MIE should have been restored from MPIE
    csrr    t0, mstatus
    andi    t0, t0, 8
    beqz    t0, fail

pass:
    j pass


trap_handler:
    csrr    t0, mcause
    li      t1, 11
    bne     t0, t1, fail

    # Read mstatus during trap handler
    csrr    t0, mstatus

    # MIE must be 0
    andi    t1, t0, 8
    bnez    t1, fail

    # MPIE (bit 7) must be 1
    li      t1, 0x80
    and     t1, t0, t1
    beqz    t1, fail

    # MPP [12:11] must equal 3
    li      t1, 0x1800
    and     t1, t0, t1

    li      t2, 0x1800
    bne     t1, t2, fail

    # Return after ECALL
    csrr    t0, mepc
    addi    t0, t0, 4
    csrw    mepc, t0

    mret


fail:
    j fail
