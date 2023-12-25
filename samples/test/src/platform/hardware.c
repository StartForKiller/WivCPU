#include <platform/hardware.h>

void uart_send(uint8_t data) {
    while(!(*((volatile uint8_t *)PORT_UART) & 0x1));
    *((volatile uint8_t *)PORT_UART) = data;
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