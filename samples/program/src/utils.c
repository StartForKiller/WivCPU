#include "types.h"
#include "utils.h"

void uart_send(uint8_t data) {
    while(!(*((volatile uint8_t *)PORT_UART) & 0x1));
    *((volatile uint8_t *)PORT_UART) = data;
}

void print(char *string) {
    char c;
    while((c = *string++) != 0) {
        uart_send((unsigned char)c);
    }
}

void spi_configure(uint8_t freq, uint8_t mode) {
    *((volatile uint8_t *)PORT_SPI_CFG) = (freq << 3) | (mode & 0x3);
}

void spi_select(uint8_t device) {
    *((volatile uint8_t *)PORT_SPI_STATUS) = device;
}

uint8_t spi_send_byte(uint8_t a) {
    *((volatile uint8_t *)PORT_SPI_DATA) = a;
    *((volatile uint8_t *)PORT_SPI_CFG) |= 0x4;

    while(*((volatile uint8_t *)PORT_SPI_STATUS) & 0x1);

    return *((volatile uint8_t *)PORT_SPI_DATA);
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