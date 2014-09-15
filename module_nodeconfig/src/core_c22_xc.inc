/************
 * Core-C22
 ************/

#pragma once

#include <xs1.h>
#include <platform.h>
#include <flash.h>

 /* SPI port definitions */ 
on tile[0]: fl_SPIPorts p_spi_flash = { PORT_SPI_MISO_0,
 								PORT_SPI_SS_0,
 								PORT_SPI_CLK_0,
 								PORT_SPI_MOSI_0,
 								XS1_CLKBLK_2 };
/* RGB LED */
//on tile[1]: out port p_core_leds[3] = { XS1_PORT_1M,   /* Red */
//					   XS1_PORT_1L,   /* Green */
//					   XS1_PORT_1K }; /* Blue */
