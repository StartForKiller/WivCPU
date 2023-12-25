#include <types.h>
#include <utils/utils.h>
#include <platform/hardware.h>

void *memset(void *dest, char c, size_t count) {
    uint8_t *a = (uint8_t *)dest;
    while(count--) *a++ = c;
    return dest;
}

void *memcpy(void *dest, void *src, size_t len) {
    uint8_t *a = (uint8_t *)dest;
    uint8_t *b = (uint8_t *)src;
    for(size_t i = 0; i < len; i++)
        *a++ = *b++;

    return dest;
}

int memcmp(void *dest, void *src, size_t len) {
    uint8_t *a = (uint8_t *)dest;
    uint8_t *b = (uint8_t *)src;
    for(size_t i = 0; i < len; i++) {
        uint8_t a_v = *a++;
        uint8_t b_v = *b++;
        if(a_v == b_v) continue;
        if(a_v < b_v) return -1;
        return 1;
    }

    return 0;
}

void print(char *string) {
    char c;
    while((c = *string++) != 0) {
        uart_send((unsigned char)c);
    }
}

void printHex8(uint8_t data) {
    char low = data & 0xF;
    char high = data >> 4;
    uart_send(high <= 9 ? (high + '0') : (high + '7'));
    uart_send(low <= 9 ? (low + '0') : (low + '7'));
}

void printHex32(uint32_t data) {
    printHex8(data >> 24);
    printHex8(data >> 16);
    printHex8(data >> 8);
    printHex8(data);
}

void printHex64(uint64_t data) {
    printHex32(data >> 32);
    printHex32(data);
}