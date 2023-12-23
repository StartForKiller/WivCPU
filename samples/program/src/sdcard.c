#include "sdcard.h"
#include "utils.h"

static inline uint8_t crc7_one(uint8_t crcIn, uint8_t data) {
    crcIn ^= data;
    for(int i = 0; i < 8; i++) {
        if(crcIn & 0x80) crcIn ^= 0x89;
        crcIn <<= 1;
    }

    return crcIn;
}
static uint8_t crc7_arg(uint8_t cmd, uint32_t data) {
    uint8_t crc = 0;

    crc = crc7_one(crc, cmd);
    for(int i = 0; i < 4; i++) {
        crc = crc7_one(crc, data >> 24);
        data <<= 8;
    }

    return crc;
}

void sdcard_send_cmd(uint8_t cmd, uint32_t arg) {
    cmd |= 0x40;
    uint8_t crc = crc7_arg(cmd, arg);

    spi_send_byte(cmd);
    spi_send_byte(arg >> 24);
    spi_send_byte(arg >> 16);
    spi_send_byte(arg >> 8);
    spi_send_byte(arg);
    spi_send_byte(crc | 0x1);
}

uint8_t sdcard_read_r1_response() {
    uint8_t response = 0xFF;
    do {
        response = spi_send_byte(0xFF);
    } while(response & 0x80);

    return response;
}

uint32_t sdcard_read_r37_response() {
    uint8_t responseTemp = 0xFF;
    do {
        responseTemp = spi_send_byte(0xFF);
    } while(responseTemp & 0x80);

    if(responseTemp & 0xFC)
        return 0;

    uint32_t response = 0;
    response |= (uint32_t)spi_send_byte(0xFF) << 24;
    response |= (uint32_t)spi_send_byte(0xFF) << 16;
    response |= (uint32_t)spi_send_byte(0xFF) << 8;
    response |= (uint32_t)spi_send_byte(0xFF);

    return response;
}

uint8_t sdcard_send_command_r1_response(uint8_t cmd, uint32_t arg) {
    spi_select(SDCARD_SPI_CS);

    sdcard_send_cmd(cmd, arg);
    uint8_t response = sdcard_read_r1_response();

    spi_select(0);

    return response;
}

uint32_t sdcard_send_command_r37_response(uint8_t cmd, uint32_t arg) {
    spi_select(SDCARD_SPI_CS);

    sdcard_send_cmd(cmd, arg);
    uint32_t response = sdcard_read_r37_response();

    spi_select(0);

    return response;
}

uint8_t send_acommand_r1_response(uint8_t cmd, uint32_t arg) {
    uint8_t response = sdcard_send_command_r1_response(55, 0);
    if(response & 0xFC)
        return response;

    return sdcard_send_command_r1_response(cmd, arg);
}

static bool sdcard_high_capcity = 0;
int sdcard_read_single_block(uint32_t lba, uint8_t *buffer, uint32_t bufferSize) {
    spi_select(SDCARD_SPI_CS);

    sdcard_send_cmd(17, sdcard_high_capcity ? lba : (lba << 9));
    uint8_t response = sdcard_read_r1_response();
    if(response & 0xFC) {
        spi_select(0);
        return -1;
    }

    do {
        response = spi_send_byte(0xFF);
    } while(response != 0xFE);

    for(int i = 0; i < 512; i++) {
        uint8_t data = spi_send_byte(0xFF);

        if(bufferSize > 0) {
            *buffer++ = data;
            bufferSize--;
        }
    }

    //Discard CRC
    spi_send_byte(0xFF);
    spi_send_byte(0xFF);

    spi_select(0);

    return 0;
}

int sdcard_init() {
    spi_configure(1, 0);

    spi_configure(1, 0);
    spi_select(2);
    for(int i = 0; i < 10; i++)
        spi_send_byte(0xFF);
    spi_select(0);

    //Send CMD0
    uint32_t response = (uint32_t)sdcard_send_command_r1_response(0, 0);
    if(!(response & 0x1)) return -1;

    //Send CMD58
    response = sdcard_send_command_r37_response(58, 0);
    if(((response >> 16) & 0xFF) != 0xFF) return -1;

    int high_capacity = 0;

    //Send CMD8 with 0x1AA
    response = (uint32_t)sdcard_send_command_r37_response(8, 0x1AA);
    if(response != 0) {
        if((response & 0x1FF) != 0x1AA)
            return -1;
        high_capacity = 1;
    }

    //Send ACMD41
    response = 0x1;
    while(response & 0x1) {
        response = (uint32_t)send_acommand_r1_response(41, ((uint32_t)high_capacity) << 30);
        if(response & 0xFC) {
            //Retry with CMD1 -> MMC
            response = (uint32_t)sdcard_send_command_r1_response(1, 0);
            if(response & 0xFC)
                return -1;

            print("MMC\n\r");
        } else {
            print("SDC\n\r");
        }
    }

    //Send CMD58 to get high capacity
    response = sdcard_send_command_r37_response(58, 0);
    if(((response >> 16) & 0xFF) != 0xFF) return -1;
    if((response >> 30) & 0x1) {
        print("High Capacity\n\r");
        high_capacity = 1;
    } else {
        high_capacity = 0;

        //Set to block length 512 bytes
        response = (uint32_t)sdcard_send_command_r1_response(16, 512);
        if(response & 0xFC)
            return -1;
    }

    sdcard_high_capcity = high_capacity;

    return 0;
}