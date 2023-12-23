#include "utils.h"

volatile uint64_t *mtime = (volatile uint64_t *)0x100002000;
volatile uint64_t *mtimecmp = (volatile uint64_t *)0x100002008;

void int_handler(trap_context_t *regs) {
    *mtimecmp = *mtime + 100000; //Increment one second

    uint64_t mcause;
    CSRR_READ(mcause, 0x342);
    if(mcause & 0x8000000000000000) {
        print("Int!\n\r");
    } else {
        while(1);
    }
}

void main() {
    print("Second stage init!\n\r\n\r");

    *mtimecmp = *mtime + 100000; //Increment one second
    CSRR_WRITE((1 << 7), 0x304);
    CSRR_WRITE((1 << 3), 0x300);

    while(1);
}