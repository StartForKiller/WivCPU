#ifndef _FAT32_H
#define _FAT32_H

#include "./types.h"

typedef int(*read_function_t)(uint32_t lba, uint8_t *buffer, uint32_t bufferSize);

int fat32_init(read_function_t readFunction);

#endif