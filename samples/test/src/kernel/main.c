#include <utils/utils.h>
#include <kernel/isr.h>
#include <kernel/memory.h>

void main() {
    print("Second stage init!\n\r\n\r");

    init_memory();

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

    init_isr();

    while(1);
}