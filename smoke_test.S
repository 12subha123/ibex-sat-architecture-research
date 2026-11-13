.option norvc
.section .text.start,"ax",@progbits
.globl _start
.type _start, @function

_start:
    li   t0, 42
    sw   t0, 0x100(zero)

    li   t1, 0x20000
    li   t2, 0x100
    sw   t2, 4(t1)

    li   t2, 0x104
    sw   t2, 8(t1)

    li   t2, 1
    sw   t2, 0(t1)

1:
    j    1b

.size _start, .-_start
