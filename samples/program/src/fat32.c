#include "fat32.h"
#include "sdcard.h"
#include "utils.h"

typedef struct {
    uint8_t boot_jmp[3];
    uint8_t oem_string[8];
    uint16_t bytes_per_sector;
    uint8_t sectors_per_cluster;
    uint16_t reserved_sectors_count;
    uint8_t fat_count;
    uint16_t root_dir_entries_count;
    uint16_t total_sectors_count;
    uint8_t media_descriptor_type;
    uint16_t sectors_per_fat_fat16;
    uint16_t sectors_per_track;
    uint16_t heads_count;
    uint32_t hidden_sectors_count;
    uint32_t large_sectors_count;
    uint32_t sectors_per_fat;
    uint16_t flags;
    uint16_t fat_version;
    uint32_t root_cluster;
    uint16_t fsinfo_sector;
    uint16_t backup_boot_sector;
} __attribute__((packed)) fat32_header_t;

typedef struct {
    uint8_t file_name[11];
    uint8_t attr;
    uint8_t reserved;
    uint8_t creation_time_tenths;
    uint16_t creation_time;
    uint16_t creation_date;
    uint16_t last_accessed_date;
    uint16_t cluster_hi;
    uint16_t modification_time;
    uint16_t modification_date;
    uint16_t cluster_lo;
    uint32_t file_size;
} __attribute__((packed)) fat32_directory_t;

static uint8_t sector_temp_buffer[512];
static uint32_t *fat_table = (uint32_t *)sector_temp_buffer;

static int fat32_prepare_sector(uint32_t address, read_function_t readFunction) {
    uint64_t lba = address >> 9;
    lba += 0x2000; //TODO
    if(readFunction(lba, sector_temp_buffer, 512))
        return -1;

    return 0;
}

void printHex(uint8_t data) {
    char low = data & 0xF;
    char high = data >> 4;
    uart_send(high <= 9 ? (high + '0') : (high + '7'));
    uart_send(low <= 9 ? (low + '0') : (low + '7'));
}

void printHex32(uint32_t data) {
    printHex(data >> 24);
    printHex(data >> 16);
    printHex(data >> 8);
    printHex(data);
}

void printBuffer(uint8_t *data, size_t size) {
    for(size_t i = 0; i < size; i++) {
        printHex(*data++);
        if(i == (size- 1) || (i % 16) == 15)
            print("\n\r");
        else
            print(", ");
    }
}

int fat32_init(read_function_t readFunction) {
    //Read a single block
    fat32_header_t header;
    if(fat32_prepare_sector(0, readFunction))
        return -1;

    memcpy(&header, sector_temp_buffer, sizeof(fat32_header_t));

    uint32_t fat_table_offset = header.reserved_sectors_count * header.bytes_per_sector;

    uint32_t first_data_sector = header.reserved_sectors_count + (header.fat_count * header.sectors_per_fat);

    uint32_t cluster = header.root_cluster;
    uint32_t cluster_sector = ((cluster - 2) * header.sectors_per_cluster) + first_data_sector;

    if(fat32_prepare_sector(cluster_sector * header.bytes_per_sector, readFunction))
        return -1;

    fat32_directory_t dir;
    uint32_t offset = 0;
    uint32_t sector = 0;
    uint8_t temp[12];
    temp[11] = 0;
    while(true) {
        if(offset >= 512) {
            offset = 0;
            sector++;
            if(sector >= header.sectors_per_cluster) {
                sector = 0;

                //Read the fat table
                if(fat32_prepare_sector(fat_table_offset * header.bytes_per_sector, readFunction))
                    return -1;

                cluster = fat_table[cluster];
                if(cluster >= 0x0FFFFFF8) return 0;

                cluster_sector = ((cluster - 2) * header.sectors_per_cluster) + first_data_sector;
            }

            if(fat32_prepare_sector((cluster_sector + sector) * header.bytes_per_sector, readFunction))
                return -1;
        }
        memcpy(&dir, sector_temp_buffer + offset, sizeof(fat32_directory_t));
        offset += sizeof(fat32_directory_t);

        if(dir.file_name[0] == 0) break;
        if(dir.attr & 0x1C) continue;

        print("Name: ");
        print((char *)dir.file_name);
        print("\n\r");
        if(!memcmp(dir.file_name, "BOOT    BIN", 11)) {
            memcpy(temp, dir.file_name, 11);
            print("Found Name: ");
            print((char *)temp);
            print("\n\r");

            uint32_t file_cluster = ((uint32_t)dir.cluster_hi << 16) | dir.cluster_lo;
            uint32_t file_cluster_sector = ((file_cluster - 2) * header.sectors_per_cluster) + first_data_sector;

            //TODO: Read cluster file onto ram directly
            uint32_t address = file_cluster_sector * header.bytes_per_sector + 0x400000;
            uint8_t *file_output = (uint8_t *)0x4000;
            for(uint32_t i = 0; i < dir.file_size; i += 512) {
                if(readFunction(address >> 9, file_output, 512))
                    return -1;
                address += 512;
                file_output += 512;
            }

            __asm__ volatile("fence.i");
            //Maybe pass some arguments here
            void (*program)(void) = (void (*)())0x4000;
            program();

            return 0;
        }
    }

    return -1;
}