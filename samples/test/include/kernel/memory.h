#ifndef _KERNEL_MEMORY_H
#define _KERNEL_MEMORY_H

#include <types.h>

extern uint64_t _free_region;
extern uint64_t _end_free_region;

#define PAGE_SIZE 0x1000

void *kmalloc(size_t size);
void kfree(void *addr);
void *krealloc(void *addr, size_t newSize);
void *kcalloc(size_t num, size_t nsize);

void init_memory();

#endif