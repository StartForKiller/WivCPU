.section ".text.boot"

.global _start
_start:
    la sp, _stack_start
    c.li a0, 0x4
    # TODO: TRAP Handler
    la t0, trap_handler_asm
    csrw 0x305, t0

    # invalid opcode
    ebreak

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

.align 2
trap_handler_asm:
    csrr t0, 0x341

    lb t1, 0(t0)
    addi t0, t0, 2
    andi t1, t1, 0x3
    xori t1, t1, 0x3
    bnez t1, write_epc_handler
    addi t0, t0, 2

write_epc_handler:
    csrw 0x341, t0

    mret

