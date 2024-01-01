#include <utils/utils.h>
#include <kernel/isr.h>
#include <kernel/memory.h>

void main(uint32_t fileSize) {
    print("Second stage init!\n\r\n\r");

    init_memory();

    print("Kernel Size: 0x"); printHex32((size_t)fileSize); print("\n\r");

    uint8_t *a = kmalloc(0x10);
    uint8_t *b = kmalloc(0x10);

    print("a: "); printHex64((size_t)a); print("\n\r");
    print("b: "); printHex64((size_t)b); print("\n\r");

    kfree(a);
    a = kmalloc(0x10);
    print("a: "); printHex64((size_t)a); print("\n\r");
    uint8_t *c = kmalloc(0x10);
    print("c: "); printHex64((size_t)c); print("\n\r");

    kfree(a);
    kfree(b);
    kfree(c);

    volatile uint64_t *test = (volatile uint64_t *)0x10000000;
    for(uint64_t i = 0; i < 8; i++) {
        *test = i;
        test = (volatile uint64_t *)(0x10000000 + ((i + 1) << 3));
    }
    asm volatile ("fence.i" ::: "memory");
    test = (volatile uint64_t *)0x10000000;
    *test = 1;
    if(*test == 1) print("Test\n\r");

    init_isr();

    while(1);
}