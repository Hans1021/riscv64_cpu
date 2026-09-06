.option norvc
.text

.globl _start
.globl pass
.globl fail

_start:
    la sp, _stack_top

    call main

    # main returns 0 on success, other on failure
    beqz a0, pass

fail:
    j fail

pass:
    j pass