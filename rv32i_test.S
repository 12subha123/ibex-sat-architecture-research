.option norvc
.section .text.start,"ax",@progbits
.globl _start
.type _start, @function

.macro CHECK reg, expected, code
    li   t0, \expected
    beq  \reg, t0, .Lok\@
    li   t1, \code
    j    report
.Lok\@:
.endm

_start:
    # Register-register arithmetic
    li   a1, 0x12345678
    li   a2, 0x0f0ff00f

    add  t2, a1, a2
    CHECK t2, 0x21444687, 1

    sub  t2, a1, a2
    CHECK t2, 0x03246669, 2

    and  t2, a1, a2
    CHECK t2, 0x02045008, 3

    or   t2, a1, a2
    CHECK t2, 0x1f3ff67f, 4

    xor  t2, a1, a2
    CHECK t2, 0x1d3ba677, 5

    # Register-register shifts
    li   a1, 0x80000001
    li   a2, 1

    sll  t2, a1, a2
    CHECK t2, 2, 6

    srl  t2, a1, a2
    CHECK t2, 0x40000000, 7

    sra  t2, a1, a2
    CHECK t2, 0xc0000000, 8

    # Immediate arithmetic and logical operations
    addi t2, a1, 5
    CHECK t2, 0x80000006, 9

    xori t2, a1, -1
    CHECK t2, 0x7ffffffe, 10

    ori  t2, zero, 0x123
    CHECK t2, 0x123, 11

    andi t2, a1, 0x7ff
    CHECK t2, 1, 12

    slli t2, a2, 4
    CHECK t2, 16, 13

    srli t2, a1, 4
    CHECK t2, 0x08000000, 14

    srai t2, a1, 4
    CHECK t2, 0xf8000000, 15

    # Signed and unsigned comparisons
    li   a1, -1
    li   a2, 1

    slt  t2, a1, a2
    CHECK t2, 1, 16

    sltu t2, a1, a2
    CHECK t2, 0, 17

    slti t2, a1, 1
    CHECK t2, 1, 18

    sltiu t2, a1, 1
    CHECK t2, 0, 19

    # Conditional branches: expected taken/not-taken paths
    beq  a1, a1, 1f
    li   t1, 20
    j    report
1:
    bne  a1, a2, 2f
    li   t1, 21
    j    report
2:
    blt  a1, a2, 3f
    li   t1, 22
    j    report
3:
    bge  a2, a1, 4f
    li   t1, 23
    j    report
4:
    bltu a2, a1, 5f
    li   t1, 24
    j    report
5:
    bgeu a1, a2, 6f
    li   t1, 25
    j    report
6:

    # Store/load byte, halfword, and word
    li   t3, 0xF100
    li   t4, 0x80ff7f01
    sw   t4, 0(t3)

    lb   t2, 2(t3)
    CHECK t2, -1, 26

    lbu  t2, 3(t3)
    CHECK t2, 0x80, 27

    lh   t2, 2(t3)
    CHECK t2, 0xffff80ff, 28

    lhu  t2, 2(t3)
    CHECK t2, 0x80ff, 29

    lw   t2, 0(t3)
    CHECK t2, 0x80ff7f01, 30

    li   t4, 0x5a
    sb   t4, 4(t3)
    lbu  t2, 4(t3)
    CHECK t2, 0x5a, 31

    li   t4, 0x1234
    sh   t4, 6(t3)
    lhu  t2, 6(t3)
    CHECK t2, 0x1234, 32

    # LUI
    lui  t2, 0x12345
    CHECK t2, 0x12345000, 33

    # All six conditional branches must not be taken
    beq  a1, a2, fail_branch_35
    bne  a1, a1, fail_branch_36
    blt  a2, a1, fail_branch_37
    bge  a1, a2, fail_branch_38
    bltu a1, a2, fail_branch_39
    bgeu a2, a1, fail_branch_40

    # AUIPC: compute and verify the address of the next instruction
    auipc t2, 1
auipc_next:
    addi  t2, t2, -2048
    addi  t2, t2, -2044
    la    t0, auipc_next
    bne   t2, t0, fail_auipc

    # JALR: verify the link address and target execution
    la    t0, jalr_target
    jalr  t2, 0(t0)
jalr_return:
    j     jalr_done
jalr_target:
    la    t0, jalr_return
    bne   t2, t0, fail_jalr
jalr_done:

    # JAL control-flow check: skipped instruction must not execute
    jal  zero, 7f
    li   t1, 34
    j    report
7:

    # All checks passed
    li   t1, 42
    j    report

fail_branch_35:
    li t1, 35
    j report
fail_branch_36:
    li t1, 36
    j report
fail_branch_37:
    li t1, 37
    j report
fail_branch_38:
    li t1, 38
    j report
fail_branch_39:
    li t1, 39
    j report
fail_branch_40:
    li t1, 40
    j report
fail_auipc:
    li t1, 41
    j report
fail_jalr:
    li t1, 50
    j report

report:
    li   t0, 0xF000
    sw   t1, 0(t0)

    li   t2, 0x20000
    li   t3, 0xF000
    sw   t3, 4(t2)
    li   t3, 0xF004
    sw   t3, 8(t2)

    li   t3, 1
    sw   t3, 0(t2)

1:
    j    1b

.size _start, .-_start
