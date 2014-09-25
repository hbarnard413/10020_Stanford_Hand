/**
 * @file test_torque-ctrl.xc
 * @brief Test illustrates usage of profile torque control
 * @author Pavan Kanajar <pkanajar@synapticon.com>
 * @author Martin Schwarz <mschwarz@synapticon.com>
 */

#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <refclk.h>
#include <xscope_wrapper.h>

#include <3xC21+dc100.inc>

#include <hall_server.h>
#include <qei_server.h>
#include <pwm_service_inv.h>
#include <adc_server_ad7949.h>
#include <commutation_server.h>
#include <drive_modes.h>
#include <statemachine.h>
#include <torque_ctrl_server.h>
#include <profile_control.h>
#include <internal_config.h>
#include <drive_modes.h>
#include <statemachine.h>
#include <torque_ctrl_client.h>
#include <profile.h>

on stdcore[NODE_0_IFM_TILE]:clock clk_adc = XS1_CLKBLK_1;
on stdcore[NODE_0_IFM_TILE]:clock clk_pwm = XS1_CLKBLK_REF;
on stdcore[NODE_1_IFM_TILE]:clock clk_adc_1 = XS1_CLKBLK_1;
on stdcore[NODE_1_IFM_TILE]:clock clk_pwm_1 = XS1_CLKBLK_REF;
on stdcore[NODE_2_IFM_TILE]:clock clk_adc_2 = XS1_CLKBLK_1;
on stdcore[NODE_2_IFM_TILE]:clock clk_pwm_2 = XS1_CLKBLK_REF;

//#define ENABLE_xscope

#define COM_TILE 0
#define IFM_TILE 1

void xscope_initialise_1()
{
	xscope_register(2,
	        XSCOPE_CONTINUOUS, "0 target_torque", XSCOPE_INT, "n",
			XSCOPE_CONTINUOUS, "1 actual_torque", XSCOPE_INT, "n");
}

/* Test Profile Torque Function */
void profile_torque_test(chanend ?c_torque_ctrl)
{

	int target_torque = 200; 	//(desired torque/torque_constant)  * IFM resolution
	int torque_slope  = 100;  	//(desired torque_slope/torque_constant)  * IFM resolution
	cst_par cst_params; int actual_torque; timer t; unsigned int time;
	init_cst_param(cst_params);

#ifdef ENABLE_xscope
	xscope_initialise_1();
#endif

	/* Set new target torque for profile torque control */
	set_profile_torque( target_torque, torque_slope, cst_params, c_torque_ctrl);

	target_torque = 0;
	set_profile_torque( target_torque, torque_slope, cst_params, c_torque_ctrl);

	target_torque = -200;
	set_profile_torque( target_torque, torque_slope, cst_params, c_torque_ctrl);
	t:>time;
	while(1)
	{
		actual_torque = get_torque(c_torque_ctrl)*cst_params.polarity;
		t when timerafter(time + MSEC_STD) :> time;
#ifdef ENABLE_xscope
		xscope_int(0, actual_torque);
#endif
	}
}

int main(void)
{
	// Motor control channels
	chan c_adc, c_adctrig;													// adc channels
	chan c_qei_p1, c_qei_p2, c_qei_p3, c_qei_p4, c_qei_p5, c_qei_p6 ; 		// qei channels
	chan c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5, c_hall_p6;	// hall channels
	chan c_commutation_p1, c_commutation_p2, c_commutation_p3, c_signal;	// commutation channels
	chan c_pwm_ctrl;														// pwm channel
	chan c_torque_ctrl,c_velocity_ctrl, c_position_ctrl;					// torque control channel
	chan c_watchdog; 														// watchdog channel

    chan c_qei_p1_1, c_qei_p2_1, c_qei_p3_1; // node 1 qei channels
    chan c_hall_p1_1, c_hall_p2_1, c_hall_p3_1, c_hall_p4_1, c_hall_p5_1,
            c_hall_p6_1; // node 1 hall channels
    chan c_commutation_p1_1, c_commutation_p2_1, c_commutation_p3_1, c_signal_1; // node 1 commutation channels
    chan c_pwm_ctrl_1, c_adctrig_1; // node 1 pwm channels
    chan c_velocity_ctrl_1; // node 1 velocity control channel
    chan c_torque_ctrl_1; // node 1 torque control channel
    chan c_watchdog_1; // node 1 WDT channel
    chan c_adc_1;//node 1 adc channel

    chan c_qei_p1_2, c_qei_p2_2, c_qei_p3_2; // node 2 qei channels
    chan c_hall_p1_2, c_hall_p2_2, c_hall_p3_2, c_hall_p4_2, c_hall_p5_2,
            c_hall_p6_2; // node 2 hall channels
    chan c_commutation_p1_2, c_commutation_p2_2, c_commutation_p3_2, c_signal_2; // node 2 commutation channels
    chan c_pwm_ctrl_2, c_adctrig_2; // node 2 pwm channels
    chan c_velocity_ctrl_2; // node 2 velocity control channel
    chan c_torque_ctrl_2; // node 2 torque control channel
    chan c_watchdog_2; // node 2 WDT channel
    chan c_adc_2;//node 2 adc channel

	    par
	        {
	            //APP - C21 node 0
	            on tile[NODE_0_APP_TILE]:
	            {
	                par {
                            {
                                //printstrln("I am 0");
                                delay_seconds(2);
                                //profile_velocity_test(c_velocity_ctrl_0, c_hall_p4_0);
                                profile_torque_test(c_torque_ctrl);
                            }

                             //Velocity Control Loop
                    /*      {
                                ctrl_par velocity_ctrl_params_0;
                                filter_par sensor_filter_params_0;
                                hall_par hall_params_0;
                                qei_par qei_params_0;

                                init_velocity_control_param(velocity_ctrl_params_0);

                                init_hall_param(hall_params_0);
                                init_qei_param(qei_params_0);

                                //Initialize sensor filter length
                                init_sensor_filter_param(sensor_filter_params_0);

                                // Control Loop
                                velocity_control(velocity_ctrl_params_0,
                                        sensor_filter_params_0, hall_params_0,
                                        qei_params_0, SENSOR_USED, c_hall_p2_0, c_qei_p2_0,
                                        c_velocity_ctrl_0, c_commutation_p2_0);
                            }
                    */

                            // Torque Control Loop
                            {
                                ctrl_par torque_ctrl_params;
                                hall_par hall_params;
                                qei_par qei_params;

                                // Initialize PID parameters for Torque Control (defined in config/motor/bldc_motor_config.h)
                                init_torque_control_param(torque_ctrl_params);

                                // Initialize Sensor configuration parameters (defined in config/motor/bldc_motor_config.h)
                                init_hall_param(hall_params);
                                init_qei_param(qei_params);


                                // Control Loop
                                torque_control( torque_ctrl_params, hall_params, qei_params, SENSOR_USED,
                                        c_adc, c_commutation_p1,  c_hall_p2,  c_qei_p3, c_torque_ctrl);
                            }
	                }
	            }

	            //IFM - C21 node 0
	            on tile[NODE_0_IFM_TILE]:
	            {
                    par
	                {
	                  // ADC Loop
                      adc_ad7949_triggered(c_adc, c_adctrig, clk_adc, p_ifm_adc_sclk_conv_mosib_mosia_0, p_ifm_adc_misoa_0,
                             p_ifm_adc_misob_0);

                      // PWM Loop
                      do_pwm_inv_triggered(c_pwm_ctrl, c_adctrig, p_ifm_dummy_port_0,
                              p_ifm_motor_hi_0, p_ifm_motor_lo_0, clk_pwm);

                      // Motor Commutation loop
                      {
                          hall_par hall_params;
                          qei_par qei_params;
                          commutation_par commutation_params;
                          init_hall_param(hall_params);
                          init_qei_param(qei_params);
                          commutation_sinusoidal(c_hall_p1,  c_qei_p1, c_signal, c_watchdog,  \
                                  c_commutation_p1, c_commutation_p2, c_commutation_p3, c_pwm_ctrl,\
                                  p_ifm_esf_rstn_pwml_pwmh_0, p_ifm_coastn_0, p_ifm_ff1_0, p_ifm_ff2_0,\
                                  hall_params, qei_params, commutation_params);
                      }

                      // Watchdog Server
                      run_watchdog(c_watchdog, p_ifm_wd_tick_0, p_ifm_shared_leds_wden_0);

                      // Hall Server
                      {
                          hall_par hall_params;
                          run_hall(c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5, c_hall_p6, p_ifm_hall_0, hall_params); // channel priority 1,2..4
                      }
	                }
	            }

	            //APP - C21 node 1
	            on tile[NODE_1_APP_TILE]:
	            {

	                par {

                            {
                                //printstrln("I am 1");
                                delay_seconds(1);
                               // profile_velocity_test(c_velocity_ctrl_1, c_hall_p4_1);
                                profile_torque_test(c_torque_ctrl_1);
                            }
                /*            // Velocity Control Loop
                            {
                                ctrl_par velocity_ctrl_params_1;
                                filter_par sensor_filter_params_1;
                                hall_par hall_params_1;
                                qei_par qei_params_1;

                                init_velocity_control_param(velocity_ctrl_params_1);

                                init_hall_param(hall_params_1);
                                init_qei_param(qei_params_1);

                                // Initialize sensor filter length
                                init_sensor_filter_param(sensor_filter_params_1);

                                // Control Loop
                                velocity_control(velocity_ctrl_params_1,
                                        sensor_filter_params_1, hall_params_1,
                                        qei_params_1, SENSOR_USED, c_hall_p2_1, c_qei_p2_1,
                                        c_velocity_ctrl_1, c_commutation_p2_1);
                            }
                */

                            /* Torque Control Loop */
                           {
                                ctrl_par torque_ctrl_params_1;
                                filter_par sensor_filter_params_1;
                                hall_par hall_params_1;
                                qei_par qei_params_1;

                                init_torque_control_param(torque_ctrl_params_1);

                                init_hall_param(hall_params_1);
                                init_qei_param(qei_params_1);

                                // Initialize sensor filter length
                               // init_sensor_filter_param(sensor_filter_params_1);

                                torque_control( torque_ctrl_params_1, hall_params_1, qei_params_1, SENSOR_USED,
                                        c_adc_1, c_commutation_p1_1,  c_hall_p3_1,  c_qei_p3_1, c_torque_ctrl_1);
                            }
	                }
	            }

	            //IFM - C21 node 1
	            on tile[NODE_1_IFM_TILE]:
	            {
	                par
	                {
	                    // ADC Loop
	                    adc_ad7949_triggered(c_adc_1, c_adctrig_1, clk_adc_1, p_ifm_adc_sclk_conv_mosib_mosia_1, p_ifm_adc_miso_1,
	                            p_ifm_adc_conv_1);

	                    // PWM Loop
	                    do_pwm_inv_triggered(c_pwm_ctrl_1, c_adctrig_1,
	                            p_ifm_dummy_port_1, p_ifm_motor_hi_1, p_ifm_motor_lo_1,
	                            clk_pwm_1);

	                    // Motor Commutation loop
	                    {
	                        hall_par hall_params_1;
	                        qei_par qei_params_1;
	                        commutation_par commutation_params_1;
	                        int init_state;
	                        init_hall_param(hall_params_1);
	                        init_qei_param(qei_params_1);
	                        commutation_sinusoidal(c_hall_p1_1, c_qei_p1_1, c_signal_1,
	                                c_watchdog_1, c_commutation_p1_1,
	                                c_commutation_p2_1, c_commutation_p3_1,
	                                c_pwm_ctrl_1, p_ifm_esf_rstn_pwml_pwmh_1,
	                                p_ifm_coastn_1, p_ifm_ff1_1, p_ifm_ff2_1,
	                                hall_params_1, qei_params_1, commutation_params_1);
	                    }

	                    // Watchdog Server
	                    run_watchdog(c_watchdog_1, p_ifm_wd_tick_1,
	                            p_ifm_shared_leds_wden_1);

	                    // Hall Server
	                    {
	                        hall_par hall_params_1;
	                        run_hall(c_hall_p1_1, c_hall_p2_1, c_hall_p3_1,
	                                c_hall_p4_1, c_hall_p5_1, c_hall_p6_1,
	                                p_ifm_hall_1, hall_params_1);
	                    }
	                }
	            }

	            //APP - C21 node 2
	            on tile[NODE_2_APP_TILE]:
	            {
	                par {

                            {
                                //printstrln("I am 2");
                                delay_seconds(0);
                                //profile_velocity_test(c_velocity_ctrl_2, c_hall_p4_2);
                                profile_torque_test(c_torque_ctrl_2);
                            }

                /*          //   Velocity Control Loop
                            {
                                ctrl_par velocity_ctrl_params_2;
                                filter_par sensor_filter_params_2;
                                hall_par hall_params_2;
                                qei_par qei_params_2;

                                init_velocity_control_param(velocity_ctrl_params_2);

                                init_hall_param(hall_params_2);
                                init_qei_param(qei_params_2);

                                // Initialize sensor filter length
                                init_sensor_filter_param(sensor_filter_params_2);

                                // Control Loop
                                velocity_control(velocity_ctrl_params_2,
                                        sensor_filter_params_2, hall_params_2,
                                        qei_params_2, SENSOR_USED, c_hall_p2_2, c_qei_p2_2,
                                        c_velocity_ctrl_2, c_commutation_p2_2);
                            }
                */

                            /* Torque Control Loop */
                            {
                                ctrl_par torque_ctrl_params_2;
                                filter_par sensor_filter_params_2;
                                hall_par hall_params_2;
                                qei_par qei_params_2;

                                init_torque_control_param(torque_ctrl_params_2);

                                init_hall_param(hall_params_2);
                                init_qei_param(qei_params_2);

                                // Initialize sensor filter length
                                //init_sensor_filter_param(sensor_filter_params_2);

                                torque_control( torque_ctrl_params_2, hall_params_2, qei_params_2, SENSOR_USED,
                                        c_adc_2, c_commutation_p1_2,  c_hall_p3_2,  c_qei_p3_2, c_torque_ctrl_2);
                            }
	                }
	            }

	            //IFM - C21 node 2
	            on tile[NODE_2_IFM_TILE]:
	            {
	                par
	                {
	                    // ADC Loop
	                    adc_ad7949_triggered(c_adc_2, c_adctrig_2, clk_adc_2, p_ifm_adc_sclk_conv_mosib_mosia_2, p_ifm_adc_miso_2,
	                            p_ifm_adc_conv_2);

	                    // PWM Loop
	                    do_pwm_inv_triggered(c_pwm_ctrl_2, c_adctrig_2,
	                            p_ifm_dummy_port_2, p_ifm_motor_hi_2, p_ifm_motor_lo_2,
	                            clk_pwm_2);

	                    // Motor Commutation loop
	                    {
	                        hall_par hall_params_2;
	                        qei_par qei_params_2;
	                        commutation_par commutation_params_2;
	                        int init_state;
	                        init_hall_param(hall_params_2);
	                        init_qei_param(qei_params_2);
	                        commutation_sinusoidal(c_hall_p1_2, c_qei_p1_2, c_signal_2,
	                                c_watchdog_2, c_commutation_p1_2,
	                                c_commutation_p2_2, c_commutation_p3_2,
	                                c_pwm_ctrl_2, p_ifm_esf_rstn_pwml_pwmh_2,
	                                p_ifm_coastn_2, p_ifm_ff1_2, p_ifm_ff2_2,
	                                hall_params_2, qei_params_2, commutation_params_2);
	                    }

	                    // Watchdog Server
	                    run_watchdog(c_watchdog_2, p_ifm_wd_tick_2,
	                            p_ifm_shared_leds_wden_2);

	                    // Hall Server
	                    {
	                        hall_par hall_params_2;
	                        run_hall(c_hall_p1_2, c_hall_p2_2, c_hall_p3_2,
	                                c_hall_p4_2, c_hall_p5_2, c_hall_p6_2,
	                                p_ifm_hall_2, hall_params_2);
	                    }
	                }
	            }

	        }

	return 0;
}
