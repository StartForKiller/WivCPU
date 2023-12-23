.section ".text.boot"

.global _start
_start:
    la sp, _stack_start
    csrwi mie, 0x0

    la t0, trap_handler_asm
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

trap_handler_asm:
    csrrw sp, mscratch, sp

    add sp, sp, -0xE8

    sd ra, 0x00(sp)
    sd gp, 0x08(sp)
    sd tp, 0x10(sp)
    sd t1, 0x18(sp)
    sd t2, 0x20(sp)
    sd s0, 0x28(sp)
    sd s1, 0x30(sp)
    sd a0, 0x38(sp)
    sd a1, 0x40(sp)
    sd a2, 0x48(sp)
    sd a3, 0x50(sp)
    sd a4, 0x58(sp)
    sd a5, 0x60(sp)
    sd a6, 0x68(sp)
    sd a7, 0x70(sp)
    sd s2, 0x78(sp)
    sd s3, 0x80(sp)
    sd s4, 0x88(sp)
    sd s5, 0x90(sp)
    sd s6, 0x98(sp)
    sd s7, 0xA0(sp)
    sd s8, 0xA8(sp)
    sd s9, 0xB0(sp)
    sd s10, 0xB8(sp)
    sd s11, 0xC0(sp)
    sd t3, 0xC8(sp)
    sd t4, 0xD0(sp)
    sd t5, 0xD8(sp)
    sd t6, 0xE0(sp)

    mv a0, sp
    call int_handler

    ld ra, 0x00(sp)
    ld gp, 0x08(sp)
    ld tp, 0x10(sp)
    ld t1, 0x18(sp)
    ld t2, 0x20(sp)
    ld s0, 0x28(sp)
    ld s1, 0x30(sp)
    ld a0, 0x38(sp)
    ld a1, 0x40(sp)
    ld a2, 0x48(sp)
    ld a3, 0x50(sp)
    ld a4, 0x58(sp)
    ld a5, 0x60(sp)
    ld a6, 0x68(sp)
    ld a7, 0x70(sp)
    ld s2, 0x78(sp)
    ld s3, 0x80(sp)
    ld s4, 0x88(sp)
    ld s5, 0x90(sp)
    ld s6, 0x98(sp)
    ld s7, 0xA0(sp)
    ld s8, 0xA8(sp)
    ld s9, 0xB0(sp)
    ld s10, 0xB8(sp)
    ld s11, 0xC0(sp)
    ld t3, 0xC8(sp)
    ld t4, 0xD0(sp)
    ld t5, 0xD8(sp)
    ld t6, 0xE0(sp)

    add sp, sp, 0xE8

    csrrw sp, mscratch, sp

    mret
