#include <pwm_test.h>

#include <pwm_service_inv.h>

#include <stdlib.h>
#include <xs1.h>
#include <platform.h>

/* For a PWM clock speed >100 MHz only the reference clock can be used.
   The reference clock can be configured in the platform XN file */
on stdcore[3]: clock clk_pwm = XS1_CLKBLK_REF;

/* Only port logic (port timer) will be used, no outputs or inputs will be performed.
   This also means that ports which share pins this port but have higher precedence
   can still be used without any limitations */
on stdcore[3]: in port p_dummy = XS1_PORT_16A;

/* High-side and low-side gate control ports for 6 half bridges */
on stdcore[3]: buffered out port:32 p_high_side[3] = { XS1_PORT_1K, XS1_PORT_1O, XS1_PORT_1M };
on stdcore[3]: buffered out port:32 p_low_side[3] = { XS1_PORT_1L, XS1_PORT_1P, XS1_PORT_1N };

/* ADC */
on stdcore[3]: out port p_adc_conv = XS1_PORT_1A;


int main (void)
{
    chan c_pwm_ctrl;            /* PWM control channel */
    chan c_adc_trigger;         /* PWM serivce will send out a control token on this channel
                                   which can be used to trigger ADC sampling during PWM off-time */

    par {
        /* PWM service */
        on stdcore[3]: {
            timer t;
            unsigned ts;

            t :> ts;
            t when timerafter (ts + 42000) :> void;
            do_pwm_inv_triggered(c_pwm_ctrl, c_adc_trigger,
                                 p_dummy, p_high_side, p_low_side,
                                 clk_pwm);
        }


        /* PWM client */
        on stdcore[3]: {
            do_pwm_test(c_pwm_ctrl);
            exit (0);
        }


        /* Using the ADC trigger */
        on stdcore[3]: {
            unsigned char ct;   /* control token received from channel */

            p_adc_conv <: 0;

            while(1) {
                select {
                case inct_byref(c_adc_trigger, ct):
                    if (ct == XS1_CT_END) {
                        /* only output a short pulse for testing purposes;
                           the adc sampling/conversion function would be called here otherwise */
                        p_adc_conv <: 1;
                        p_adc_conv <: 0;
                    }
                    break;
                }
            }
        }
    }
}
