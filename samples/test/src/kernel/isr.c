#include <kernel/isr.h>
#include <platform/hardware.h>
#include <utils/utils.h>

#define REG_COUNT 32
char *names[REG_COUNT] = {
    "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5", "a6",
    "a7", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6", "mepc"
};

void print_isr_context(isr_context_t *regs) {
    uint64_t *reg_array = (uint64_t *)regs;
    for(int i = 0; i < REG_COUNT; i++) {
        print(names[i]);
        print(": 0x");
        printHex64(reg_array[i]);
        print("\n\r");
    }
}

void trap_handler(isr_context_t *regs) {
    print("TRAP EXCEPTION!\n\rReg Dump:\n\r");
    print_isr_context(regs);

    print("\n\r");
    while(1);
}

volatile uint64_t tick_count = 0;
void isr_handler(isr_context_t *regs) {
    *MTIMECMP = *MTIME + (SYSCLOCK_FREQ/10UL); //Increment 100 milliseconds

    //uint64_t mcause;
    //CSRR_READ(mcause, CSR_MCAUSE);

    tick_count++;
    if(tick_count % 20 == 0) {
        print("Int!\n\rReg Dump:\n\r");
        print_isr_context(regs);

        print("\n\r");
    }
}

void init_isr() {
    *MTIMECMP = *MTIME + (SYSCLOCK_FREQ/10UL); //Increment 100 milliseconds

    CSRR_WRITE((1 << 7), CSR_MIE);      //Enable timer interrupts
    CSRR_WRITE((1 << 3), CSR_MSTATUS);  //Enable global interrupts
}