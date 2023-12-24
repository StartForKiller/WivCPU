#include <utils/utils.h>
#include <kernel/isr.h>

#define REG_COUNT 32
char *names[REG_COUNT] = {
    "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5", "a6",
    "a7", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6", "mepc"
};

void printHex(uint8_t data) {
    char low = data & 0xF;
    char high = data >> 4;
    uart_send(high <= 9 ? (high + '0') : (high + '7'));
    uart_send(low <= 9 ? (low + '0') : (low + '7'));
}

void printHex32(uint32_t data) {
    printHex(data >> 24);
    printHex(data >> 16);
    printHex(data >> 8);
    printHex(data);
}

void printHex64(uint64_t data) {
    printHex32(data >> 32);
    printHex32(data);
}

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

void isr_handler(isr_context_t *regs) {
    *MTIMECMP = *MTIME + 400000; //Increment one second

    //uint64_t mcause;
    //CSRR_READ(mcause, CSR_MCAUSE);

    print("Int!\n\rReg Dump:\n\r");
    print_isr_context(regs);

    print("\n\r");
}

void main() {
    print("Second stage init!\n\r\n\r");

    *MTIMECMP = *MTIME + 400000; //Increment one second
    CSRR_WRITE((1 << 7), CSR_MIE);
    CSRR_WRITE((1 << 3), CSR_MSTATUS);

    while(1);
}