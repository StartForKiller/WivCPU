#include <kernel/memory.h>
#include <utils/utils.h>

static uint64_t *mem_bitmap;
static uint64_t mem_start_address;
static uint64_t mem_start_address_relative_index;
static uint64_t regions_left;

static int mem_read_bit(size_t index) {
    return (mem_bitmap[(index / 64UL)] & (1UL << (index % 64UL))) == (1UL << (index % 64UL));
}

static void mem_write_bit(size_t index, int bit, size_t count) {
    for(; count; count--, index++) {
        if(bit) mem_bitmap[(index / 64UL)] |=  (1UL << (index % 64UL));
        else    mem_bitmap[(index / 64UL)] &= ~(1UL << (index % 64UL));
    }
}

static int mem_bitmap_isfree(size_t index, size_t count) {
    for(; count; index++, count--)
        if(mem_read_bit(index)) return 0;

    return 1;
}

void *mem_alloc_nonzero(size_t count) {
    size_t index = 0;
    size_t max_index = ((size_t)&_end_free_region - mem_start_address) >> 4;

    while(index < max_index) {
        if(!mem_bitmap_isfree(index, count)) {
            index++;
            continue;
        }
        mem_write_bit(index, 1, count);
        if(regions_left) regions_left -= count;

        return (void *)((index + mem_start_address_relative_index) << 4);
    }

    return NULL;
}

void *mem_alloc(size_t count) {
    void *addr = mem_alloc_nonzero(count);
    memset(addr, 0, count << 4);
    return addr;
}

void mem_free(void *addr, size_t count) {
    size_t index = ((size_t)addr - mem_start_address) >> 4;
    mem_write_bit(index, 0, count);
    regions_left += count;
}

typedef struct header {
    size_t pages;
    size_t size;
} header_t;

void *kmalloc(size_t size) {
    if(!size) return NULL;

    size_t page_size = size >> 4;
    if(size % 0x10) page_size++;

    uint8_t *ret = mem_alloc(page_size + 1);
    if(!ret) return NULL;

    header_t *header = (header_t *)ret;
    ret += 0x10;

    header->pages = page_size;
    header->size = size;

    return (void *)ret;
}

void kfree(void *addr) {
    header_t *header = (header_t *)((size_t)addr - 0x10);

    mem_free((void *)header, header->pages + 1);
}

void *krealloc(void *addr, size_t newSize) {
    if(!addr) return kmalloc(newSize);
    if(!newSize) {
        kfree(addr);
        return NULL;
    }

    header_t *header = (header_t *)((size_t)addr - 0x10);

    if(((header->size + 0x10 - 1) >> 4) == ((newSize + 0x10 - 1) >> 4)) {
        header->size = newSize;
        return addr;
    }

    uint8_t *new_addr;
    if((new_addr = kmalloc(newSize)) == 0) {
        return NULL;
    }

    if(header->size > newSize) memcpy(new_addr, (void *)addr, newSize);
    else memcpy(new_addr, (void *)addr, header->size);

    kfree(addr);

    return (void *)new_addr;
}

void *kcalloc(size_t num, size_t nsize) {
    size_t size;
	void *block;
	if (!num || !nsize)
		return NULL;
	size = num * nsize;
	if (nsize != size / num)
		return NULL;
	block = kmalloc(size);
	if (!block)
		return NULL;
	memset(block, 0, size);
	return block;
}

#define ROUND_UP(N, S) ((((N) + (S) - 1) / (S)) * (S))
void init_memory() {
    uint64_t bitmapByteSize = (((size_t)&_end_free_region-(size_t)&_free_region) >> 7);
    bitmapByteSize = ROUND_UP(bitmapByteSize, 0x10);
    mem_bitmap = (uint64_t *)&_free_region;

    mem_start_address = (size_t)&_free_region + bitmapByteSize;
    mem_start_address_relative_index = mem_start_address >> 4;
}