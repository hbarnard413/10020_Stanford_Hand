
/**
 * @file flash_write.c
 * @brief Flash device access
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <flashlib.h>
#include <platform.h>
#include <flash.h>
#include <flash_somanet.h>

void flash_setup(int factory, fl_SPIPorts *SPI)  // could have arguments to specify the upgarde image
{
    if (fl_connect(SPI) == 0) {
        // successfully connected to flash

        // Disable flash protection for writing image
        fl_setProtection(0);
        fl_eraseAll();
    } else {
        printf("could not connect flash\n" );
        exit(1);
    }
}

void connect_to_flash(fl_SPIPorts *SPI)
{
    if (fl_connect(SPI) != 0) {
        printf("could not connect flash\n" );
        exit(1);
    }
}

void flash_buffer(unsigned char content[BUFFER_SIZE], int image_size, unsigned address)
{
    const unsigned page_size = 256;
    unsigned current_page = 0;

    for (int i=0; i<(image_size/page_size); i++) {
        fl_writePage(address, &content[current_page]);
        current_page += page_size;
        address += page_size;
    }
}

