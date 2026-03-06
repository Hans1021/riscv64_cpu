.option norvc
.text
.globl _start

_start:
    # set stack pointer
    la sp, _stack_top

    # call main()
    call main

// if main returns, halt
    ebreak
