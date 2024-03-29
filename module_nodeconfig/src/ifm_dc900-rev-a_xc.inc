#pragma once

#include <xs1.h>
#include <platform.h>

/**********************
 * Ifm Drive BLDC 100
 **********************/

/* ADC */
on stdcore[3]: in buffered  port:32 p_ifm_adc_misoa_0 = XS1_PORT_1D;
on stdcore[3]: in buffered  port:32 p_ifm_adc_misob_0 = XS1_PORT_1C;
on stdcore[3]: buffered out port:32 p_ifm_adc_sclk_conv_mosib_mosia_0 = XS1_PORT_4C;

/* A4915 control ports */
on stdcore[3]: port p_ifm_coastn_0 = XS1_PORT_1G;
on stdcore[3]: out port p_ifm_esf_rstn_pwml_pwmh_0 = XS1_PORT_4F;
on stdcore[3]: port p_ifm_ff1_0 = XS1_PORT_1H;
on stdcore[3]: port p_ifm_ff2_0 = XS1_PORT_1I;

/* BLDC Motor, default port mode */
on stdcore[3]:          in  port p_ifm_hall_0 = XS1_PORT_4E;
on stdcore[3]:          in  port p_ifm_encoder_0 = XS1_PORT_4A; /* Encoder and Button 2 */
on stdcore[3]:          in  port p_ifm_dummy_port_0 = XS1_PORT_16B; /* any unused port */
on stdcore[3]: buffered out port:32 p_ifm_motor_hi_0[3] = { XS1_PORT_1K,   /* Hi A */
							XS1_PORT_1O,   /* Hi B */
							XS1_PORT_1M }; /* Hi C */
on stdcore[3]: buffered out port:32 p_ifm_motor_lo_0[3] = { XS1_PORT_1L,   /* Lo A */
							  XS1_PORT_1P,   /* Lo B */
							  XS1_PORT_1N }; /* Lo C */
/* BLDC Motor, alternative declaration for low-side PWM */
//on stdcore[3]: out port p_ifm_motor_hi[1] = { XS1_PORT_1K,   /* Hi A */
//					      XS1_PORT_1O,   /* Hi B */
//					      XS1_PORT_1M }; /* Hi C */
//on stdcore[3]: out port p_ifm_motor_lo[1] = { XS1_PORT_1L,   /* Lo A */
//					      XS1_PORT_1P,   /* Lo B */
//					      XS1_PORT_1N }; /* Lo C */

/* LEDs, Watchdog */
on stdcore[3]: out port p_ifm_shared_leds_wden_0 = XS1_PORT_4B; /* BlueGreenRed_WDEN */
on stdcore[3]: out port p_ifm_wd_tick_0 = XS1_PORT_1F; /* WatchdogTick */

/* Expansion Port */
on stdcore[3]: port p_ifm_ext_d_0[4] ={ XS1_PORT_1A,
									  XS1_PORT_1E,
									  XS1_PORT_1J,
									  XS1_PORT_1B };