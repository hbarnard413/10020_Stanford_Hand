/**
 * @file
 * @brief Brushed Motor Drive Server
 * @author Pavan Kanajar <pkanajar@synapticon.com>
 * @author Martin Schwarz <mschwarz@synapticon.com>
*/

#include <brushed_dc_server.h>
#include <xs1.h>
#include <pwm_config.h>
#include <pwm_cli_inv.h>
#include <a4935.h>
#include <sine_table_big.h>
#include <adc_client_ad7949.h>
#include <hall_client.h>
#include <refclk.h>
#include <qei_client.h>
#include <brushed_dc_common.h>
#include <internal_config.h>
#include <watchdog.h>

void pwm_init_to_zero(chanend c_pwm_ctrl, t_pwm_control &pwm_ctrl)
{
    unsigned int pwm[3] = {0, 0, 0};  // PWM OFF
    pwm_share_control_buffer_address_with_server(c_pwm_ctrl, pwm_ctrl);
    update_pwm_inv(pwm_ctrl, c_pwm_ctrl, pwm);
}

void bdc_client_handler(chanend c_voltage, int command, int & voltage, int init_state, int & shutdown)
{
    switch (command) {
    case BDC_CMD_SET_VOLTAGE:
        c_voltage :> voltage; //TODO if any winding type differences?
        break;

    case BDC_CMD_CHECK_BUSY:                // init signal
        c_voltage <: init_state;
        break;

    case BDC_CMD_DISABLE_FETS:
        shutdown = 1;
        break;

    case BDC_CMD_ENABLE_FETS:
        shutdown = 0;
        voltage = 0;
        break;

    case BDC_CMD_FETS_STATE:
        c_voltage <: shutdown;
        break;

    default:
        break;
    }
}

static void bldc_internal_loop(port p_ifm_ff1, port p_ifm_ff2, port p_ifm_coastn,
                               t_pwm_control &pwm_ctrl, int init_state,
                               chanend c_pwm_ctrl, chanend c_signal,
                               chanend c_voltage_p1, chanend c_voltage_p2, chanend c_voltage_p3)
{
    unsigned int command;
    unsigned int pwm[3] = { 0, 0, 0 };
    int voltage = 0;
    int shutdown = 0; // Disable FETS
    int pwm_half = (PWM_MAX_VALUE - PWM_DEAD_TIME) >> 1;

    while (1) {
        if (shutdown == 1) {
            pwm[0] = -1;
            pwm[1] = -1;
            pwm[2] = -1;
        } else {
            if (voltage >= 0) {
                if (voltage <= pwm_half) {
                    pwm[0] = pwm_half + voltage;
                    pwm[1] = pwm_half;
                    pwm[2] = pwm_half;
                } else if (voltage > pwm_half && voltage < BDC_PWM_CONTROL_LIMIT) {
                    pwm[0] = pwm_half + pwm_half;
                    pwm[1] = pwm_half - (voltage - pwm_half);
                    pwm[2] = pwm_half;
                }
            } else {
                if (-voltage <= pwm_half) {
                    pwm[0] = pwm_half;
                    pwm[1] = pwm_half - voltage;
                    pwm[2] = pwm_half;
                } else if ( (-voltage > pwm_half) && (-voltage < BDC_PWM_CONTROL_LIMIT) ) {
                    pwm[0] = pwm_half - (-voltage - pwm_half);
                    pwm[1] = pwm_half + pwm_half;
                    pwm[2] = pwm_half;
                }
            }

            if(pwm[0] < PWM_MIN_LIMIT)
                pwm[0] = 0;
            if(pwm[1] < PWM_MIN_LIMIT)
                pwm[1] = 0;
            if(pwm[2] < PWM_MIN_LIMIT)
                pwm[2] = 0;
        }

        update_pwm_inv(pwm_ctrl, c_pwm_ctrl, pwm);

#pragma ordered
        select {
        case c_voltage_p1 :> command:
            bdc_client_handler( c_voltage_p1, command, voltage,
                                init_state, shutdown );
            break;

        case c_voltage_p2 :> command:
            bdc_client_handler( c_voltage_p2, command, voltage,
                                init_state, shutdown );
            break;

        case c_voltage_p3 :> command:
            bdc_client_handler( c_voltage_p3, command, voltage,
                                init_state, shutdown );
            break;

        case c_signal :> command:
            if (command == CHECK_BUSY) { // init signal
                c_signal <: init_state;
            }
            break;
        }
    }
}


void bdc_loop(chanend c_watchdog, chanend c_signal,
              chanend c_voltage_p1, chanend c_voltage_p2, chanend c_voltage_p3,
              chanend c_pwm_ctrl,
              out port p_ifm_esf_rstn_pwml_pwmh, port p_ifm_coastn, port p_ifm_ff1, port p_ifm_ff2)
{
    const unsigned t_delay = 300*USEC_FAST;
    timer t;
    unsigned int ts;
    t_pwm_control pwm_ctrl;
    int check_fet;
    int init_state = INIT_BUSY;

    pwm_init_to_zero(c_pwm_ctrl, pwm_ctrl);

    // enable watchdog
    t :> ts;
    t when timerafter (ts + 250000*4):> ts;
    c_watchdog <: WD_CMD_START;

    t :> ts;
    t when timerafter (ts + t_delay) :> ts;

    a4935_init(A4935_BIT_PWML | A4935_BIT_PWMH, p_ifm_esf_rstn_pwml_pwmh, p_ifm_coastn);
    t when timerafter (ts + t_delay) :> ts;

    p_ifm_coastn :> check_fet;
    init_state = check_fet;

    bldc_internal_loop(p_ifm_ff1, p_ifm_ff2, p_ifm_coastn, pwm_ctrl, init_state,
                       c_pwm_ctrl, c_signal, c_voltage_p1, c_voltage_p2, c_voltage_p3);
}

