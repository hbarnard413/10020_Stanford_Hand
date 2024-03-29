/**
 * @file ecat_motor_drive.h
 * @brief Ethercat Motor Drive Server
 * @author Pavan Kanajar <pkanajar@synapticon.com>
*/

#pragma once

/**
 * @brief This server implementation enables motor drive functions via Ethercat communication
 *
 * @Input Channel
 * @param pdo_in channel to receive information from ethercat
 * @param coe_out channel to receive motor config information from ethercat
 * @param c_signal channel to receive init ack from commutation loop
 * @param c_hall channel to receive position information from hall
 * @param c_qei channel to receive position information from qei
 *
 * @Output Channel
 * @param pdo_out channel to send out information via ethercat
 * @param c_torque_ctrl channel to receive/send torque control information
 * @param c_velocity_ctrl channel to receive/send velocity control information
 * @param c_position_ctrl channel to receive/send position control information
 * @param c_gpio channel to config/read/drive GPIO digital ports
 *
 */
void ecat_motor_drive(chanend pdo_out, chanend pdo_in, chanend coe_out, chanend c_signal, chanend c_hall,\
        chanend c_qei, chanend c_torque_ctrl, chanend c_velocity_ctrl, chanend c_position_ctrl, chanend c_gpio);

int detect_sensor_placement(chanend c_hall, chanend c_qei, chanend c_commutation);

