#ifndef _PLATFORM_HARDWARE_H
#define _PLATFORM_HARDWARE_H

#include <types.h>

#define PORT_UART          0x100000000
#define PORT_SPI_CFG       0x100001000
#define PORT_SPI_STATUS    0x100001008
#define PORT_SPI_DATA      0x100001010
#define PORT_SPI_CHIP      0x100001018
#define PORT_MTIME         0x100002000
#define PORT_MTIMECMP      0x100002008

#define SYSCLOCK_FREQ      400000UL

#define CSR_MSTATUS     0x300
#define CSR_MIE         0x304
#define CSR_MCAUSE      0x342

#define MTIME ((volatile uint64_t *)PORT_MTIME)
#define MTIMECMP ((volatile uint64_t *)PORT_MTIMECMP)

void uart_send(uint8_t data);

void spi_configure(uint8_t freq, uint8_t mode);
void spi_select(uint8_t device);
uint8_t spi_send_byte(uint8_t a);


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