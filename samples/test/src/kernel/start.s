.section ".text.boot"

.global _start
_start:
    la sp, _stack_start
    csrwi mie, 0x0

    la t0, trap_handler_asm
    addi t0, t0, 1
    csrw mtvec, t0

    la t0, _trap_stack_start
    csrw mscratch, t0

    call main
_halt:
    j _halt

.global __muldi3
__muldi3:
    mv     a2, a0
    li     a0, 0
__muldi3.L1:
    andi   a3, a1, 1
    beqz   a3, __muldi3.L2
    add    a0, a0, a2
__muldi3.L2:
    srli   a1, a1, 1
    slli   a2, a2, 1
    bnez   a1, __muldi3.L1
    ret

.global __umoddi3
__umoddi3:
    move  t0, ra
    jal   __udivdi3
    move  a0, a1
    jr    t0

.global __udivdi3
__udivdi3:
    mv    a2, a1
    mv    a1, a0
    li    a0, -1
    beqz  a2, __udivdi3.L5
    li    a3, 1
    bgeu  a2, a1, __udivdi3.L2
__udivdi3.L1:
    blez  a2, __udivdi3.L2
    slli  a2, a2, 1
    slli  a3, a3, 1
    bgtu  a1, a2, __udivdi3.L1
__udivdi3.L2:
    li    a0, 0
__udivdi3.L3:
    bltu  a1, a2, __udivdi3.L4
    sub   a1, a1, a2
    or    a0, a0, a3
__udivdi3.L4:
    srli  a3, a3, 1
    srli  a2, a2, 1
    bnez  a3, __udivdi3.L3
__udivdi3.L5:
    ret
