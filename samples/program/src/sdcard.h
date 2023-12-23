#ifndef _SDCARD_H
#define _SDCARD_H

#include "./types.h"

#define SDCARD_SPI_CS 1

void sdcard_send_cmd(uint8_t cmd, uint32_t arg);
uint8_t sdcard_read_r1_response();
uint32_t sdcard_read_r37_response();
uint8_t sdcard_send_command_r1_response(uint8_t cmd, uint32_t arg);
uint32_t sdcard_send_command_r37_response(uint8_t cmd, uint32_t arg);
uint8_t sdcard_send_acommand_r1_response(uint8_t cmd, uint32_t arg);
int sdcard_read_single_block(uint32_t lba, uint8_t *buffer, uint32_t bufferSize);
int sdcard_init();

#endif