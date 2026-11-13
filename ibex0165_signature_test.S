.section .text
.globl _start
.option norvc

_start:
    li t0, 0x100
    li t1, 0x13579bdf
    sw t1, 0(t0)

    li t2, 0x100
    li t3, 0x104
    li t4, 0x20004
    sw t2, 0(t4)

    li t4, 0x20008
    sw t3, 0(t4)

    li t4, 0x20000
    sw zero, 0(t4)

halt:
    j halt
