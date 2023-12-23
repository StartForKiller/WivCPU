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

typedef struct {
    uint64_t ra;
    uint64_t gp;
    uint64_t tp;
    uint64_t t1;
    uint64_t t2;
    uint64_t s0;
    uint64_t s1;
    uint64_t a0;
    uint64_t a1;
    uint64_t a2;
    uint64_t a3;
    uint64_t a4;
    uint64_t a5;
    uint64_t a6;
    uint64_t a7;
    uint64_t s2;
    uint64_t s3;
    uint64_t s4;
    uint64_t s5;
    uint64_t s6;
    uint64_t s7;
    uint64_t s8;
    uint64_t s9;
    uint64_t s10;
    uint64_t s11;
    uint64_t t3;
    uint64_t t4;
    uint64_t t5;
    uint64_t t6;
} trap_context_t;

#define CSRR_READ(v, csr)                           \
/* CSRR_READ(v, csr):
 * csr: MUST be a compile time integer 12-bit constant (0-4095)
 */                                             \
__asm__ __volatile__ ("csrr %0, %1"             \
              : "=r" (v)                        \
              : "n" (csr)                       \
              : /* clobbers: none */ );

#define CSRR_WRITE(v, csr)                           \
/* CSRR_READ(v, csr):
 * csr: MUST be a compile time integer 12-bit constant (0-4095)
 */                                             \
__asm__ __volatile__ ("csrw %1, %0"             \
              :                                 \
              : "r"(v), "n" (csr)               \
              : /* clobbers: none */ );

#endif