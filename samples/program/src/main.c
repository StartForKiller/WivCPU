#include "utils.h"
#include "sdcard.h"
#include "fat32.h"

void main() {
    print("Hello world!\n\r\n\r");

    print("Print Test Done\n\r");

    if(sdcard_init()) {
        print("SdCard Init Failed\n\r");
    } else {
        print("SdCard Init OK\n\r");

        if(fat32_init(sdcard_read_single_block))
            print("Fat32 Init Failed\n\r");
        else
            print("Finished Init procedure\n\r");
    }

    //uint8_t buffer[512];
    //if(sdcard_read_single_block(0x2000, buffer, 512)) {
    //    print("SdCard Read Failed\n\r");
    //}
    //printBuffer(buffer, 512);

    while(1);
}