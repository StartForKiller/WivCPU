#ifndef _UTILS_UTILS_H
#define _UTILS_UTILS_H

#include <types.h>

void print(char *string);

void *memset(void *dest, char c, size_t count);
void *memcpy(void *dest, void *src, size_t len);
int memcmp(void *dest, void *src, size_t len);

void printHex8(uint8_t data);
void printHex32(uint32_t data);
void printHex64(uint64_t data);

#define READ_ONCE(x) (*(volatile typeof(x) *)&(x))
#define WRITE_ONCE(var, val) \
	(*((volatile typeof(val) *)(&(var))) = (val))

#endif