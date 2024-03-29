/**
 * @file
 * @brief Brushed Motor Drive Client function
 * @author Pavan Kanajar <pkanajar@synapticon.com>
 * @author Martin Schwarz <mschwarz@synapticon.com>
 */

#pragma once

/**
 * @brief Set Input voltage for brushed dc motor
 *
 * @Output
 * @param c_voltage channel to send out motor voltage input value
 *
 * @Input
 * @param input_voltage is motor voltage input value to be set range allowed [-BDC_PWM_CONTROL_LIMIT to BDC_PWM_CONTROL_LIMIT]
 */
void set_bdc_voltage(chanend c_voltage, int input_voltage);

