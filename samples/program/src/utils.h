#ifndef _UTILS_H
#define _UTILS_H

#include "./types.h"

#define PORT_UART          0x100000000
#define PORT_SPI_CFG       0x100001000
#define PORT_SPI_STATUS    0x100001008
#define PORT_SPI_DATA      0x100001010
#define PORT_SPI_CHIP      0x100001018

void uart_send(uint8_t data);
void print(char *string);

void spi_configure(uint8_t freq, uint8_t mode);
void spi_select(uint8_t device);
uint8_t spi_send_byte(uint8_t a);

void *memcpy(void *dest, void *src, size_t len);
int memcmp(void *dest, void *src, size_t len);

#endif