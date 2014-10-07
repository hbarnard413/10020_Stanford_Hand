/**
 * @file flash_somanet.h
 * @brief Somanet Firmware Update Implemtation
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <flashlib.h>
#include <xccompat.h>

/**
 * Buffer size for the firmware image.
 */
#define BUFFER_SIZE     2400

/**
 * Command if flash is ready.
 */
#define READY_TO_FLASH  20

/**
 * @brief Firmware update handler
 *
 * This function waits for flash update transfere in module ethercat
 * and perfroms the necessary steps to update this node and any subsequent
 * node connected.
 *
 * @note This thread must be on CORE 0 only
 *
 * @param &SPI          reference to the asociated SPI ports
 * @param foe_comm      data channel for FoE communication
 * @param foe_signal    FoE signal channel
 * @param c_flash_data  channel to flash data (r/w)
 * @param c_nodes[]     channel to subsequent nodes
 * @param reset         signal from firmware updater a reset occured.
 */
void firmware_update_loop(REFERENCE_PARAM(fl_SPIPorts, SPI), chanend foe_comm, chanend foe_signal,
                          chanend c_flash_data, chanend c_nodes[], NULLABLE_RESOURCE(chanend, reset));

void firmware_update_dx(REFERENCE_PARAM(fl_SPIPorts, SPI), chanend c_node, int node_number);

int read_data_flash(chanend c_flash_data, unsigned page, unsigned char data[256],
                    unsigned data_length);

int write_data_to_flash(chanend c_flash_data, unsigned page, unsigned char data[256],
                        unsigned data_length);

// int_32 split into 4 bytes for data storage
void store_data_array(int offset, int param, char data_array[]);

// pack data bytes into int_32
int read_data_array(int offset, char data_array[]);

/* software auto reset functions */
void reset_cores(chanend sig_in, NULLABLE_RESOURCE(chanend, sig_out));

