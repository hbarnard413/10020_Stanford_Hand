/***************************
 * IFM Drive DC-300 Rev. A
 ***************************/

#pragma once

/* ADC */
extern in buffered  port:32 p_ifm_adc_misoa_0;
extern in buffered  port:32 p_ifm_adc_misob_0;
extern buffered out port:32 p_ifm_adc_sclk_conv_mosib_mosia_0;

/* A4935 control ports */
extern port p_ifm_coastn_0;
extern out port p_ifm_esf_rstn_pwml_pwmh_0;
extern     port p_ifm_ff1_0;
extern     port p_ifm_ff2_0;

/* BLDC Motor, default port mode */
extern           in  port p_ifm_hall_0;
extern           in  port p_ifm_encoder_0;
extern           in  port p_ifm_dummy_port_0; /* needed for PWM ADC-trigger timing */
extern  buffered out port:32 p_ifm_motor_hi_0[3]; /* = { Hi A, Hi B, Hi C } */
extern  buffered out port:32 p_ifm_motor_lo_0[3]; /* = { Hi A, Hi B, Hi C } */

/* BLDC Motor, alternative declaration for low-side PWM */
//extern    out port p_motor_pwm_hi[3]; /* = { Hi A, Hi B, Hi C } */
//extern    out port p_ifm_motor_lo[3]; /* = { Lo A, Lo B, Lo C } */

/* LEDs, Watchdog */
extern out port p_ifm_shared_leds_wden_0; /* BlueGreenRed_WDEN */
extern out port p_ifm_wd_tick_0;

/* Expansion Port */
extern port p_ifm_ext_d_0[4];


