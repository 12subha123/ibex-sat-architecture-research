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
    # Signed -7 and unsigned 3
    li   a1, -7
    li   a2, 3

    mul    t2, a1, a2
    CHECK  t2, -21, 1

    mulh   t2, a1, a2
    CHECK  t2, -1, 2

    mulhsu t2, a1, a2
    CHECK  t2, -1, 3

    mulhu  t2, a1, a2
    CHECK  t2, 2, 4

    div    t2, a1, a2
    CHECK  t2, -2, 5

    divu   t2, a1, a2
    CHECK  t2, 0x55555553, 6

    rem    t2, a1, a2
    CHECK  t2, -1, 7

    remu   t2, a1, a2
    CHECK  t2, 0, 8

    # Division by zero
    li   a2, 0

    div    t2, a1, a2
    CHECK  t2, -1, 9

    divu   t2, a1, a2
    CHECK  t2, -1, 10

    rem    t2, a1, a2
    CHECK  t2, -7, 11

    remu   t2, a1, a2
    CHECK  t2, -7, 12

    # Signed division overflow: INT_MIN / -1
    li   a1, 0x80000000
    li   a2, -1

    div    t2, a1, a2
    CHECK  t2, 0x80000000, 13

    rem    t2, a1, a2
    CHECK  t2, 0, 14

    # All checks passed
    li   t1, 42
    j    report

report:
    # Store result outside the firmware code area
    li   t0, 0xF000
    sw   t1, 0(t0)

    # Configure signature range [0xF000, 0xF004)
    li   t2, 0x20000
    li   t3, 0xF000
    sw   t3, 4(t2)
    li   t3, 0xF004
    sw   t3, 8(t2)

    # Trigger signature dump and termination
    li   t3, 1
    sw   t3, 0(t2)

1:
    j    1b

.size _start, .-_start
