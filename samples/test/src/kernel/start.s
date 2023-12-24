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
.L1:
    andi   a3, a1, 1
    beqz   a3, .L2
    add    a0, a0, a2
.L2:
    srli   a1, a1, 1
    slli   a2, a2, 1
    bnez   a1, .L1
    ret
