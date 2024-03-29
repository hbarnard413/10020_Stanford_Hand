/**
 * @brief Test illustrates usage of profile torque control on a complex DX topology
 * @author Agustin Tena <atena@synapticon.com>
 *
 */

#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <refclk.h>
#include <xscope_wrapper.h>

#include <C22-3xC21+dc100.inc>

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

#include <velocity_ctrl_server.h>
#include <position_ctrl_server.h>
#include <ethercat.h>
#include <ecat_motor_drive.h>
#include <gpio_server.h>

on stdcore[NODE_0_IFM_TILE]:clock clk_adc = XS1_CLKBLK_1;
on stdcore[NODE_0_IFM_TILE]:clock clk_pwm = XS1_CLKBLK_REF;
on stdcore[NODE_1_IFM_TILE]:clock clk_adc_1 = XS1_CLKBLK_1;
on stdcore[NODE_1_IFM_TILE]:clock clk_pwm_1 = XS1_CLKBLK_REF;
on stdcore[NODE_2_IFM_TILE]:clock clk_adc_2 = XS1_CLKBLK_1;
on stdcore[NODE_2_IFM_TILE]:clock clk_pwm_2 = XS1_CLKBLK_REF;
on stdcore[NODE_3_IFM_TILE]:clock clk_adc_3 = XS1_CLKBLK_1;
on stdcore[NODE_3_IFM_TILE]:clock clk_pwm_3 = XS1_CLKBLK_REF;

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
void profile_torque_test(chanend c_torque_ctrl)
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
    // EtherCat Communication channels
    chan coe_in;          // CAN from module_ethercat to consumer
    chan coe_out;         // CAN from consumer to module_ethercat
    chan eoe_in;          // Ethernet from module_ethercat to consumer
    chan eoe_out;         // Ethernet from consumer to module_ethercat
    chan eoe_sig;
    chan foe_in;              // File from module_ethercat to consumer
    chan foe_out;             // File from consumer to module_ethercat
    chan pdo_in;
    chan pdo_out;
    chan c_nodes[1], c_flash_data; // Firmware channels

	// Motor control channels
	chan c_adc, c_adctrig;													// adc channels
	chan c_qei_p1, c_qei_p2, c_qei_p3, c_qei_p4, c_qei_p5, c_qei_p6 ; 		// qei channels
	chan c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5, c_hall_p6;	// hall channels
	chan c_commutation_p1, c_commutation_p2, c_commutation_p3, c_signal;	// commutation channels
	chan c_pwm_ctrl;														// pwm channel
	chan c_torque_ctrl,c_velocity_ctrl, c_position_ctrl;					// torque control channel
	chan c_watchdog;
	chan c_gpio_p1, c_gpio_p2;                                                         // watchdog channel

    chan c_qei_p1_1, c_qei_p2_1, c_qei_p3_1; // node 1 qei channels
    chan c_hall_p1_1, c_hall_p2_1, c_hall_p3_1, c_hall_p4_1, c_hall_p5_1,
            c_hall_p6_1; // node 1 hall channels
    chan c_commutation_p1_1, c_commutation_p2_1, c_commutation_p3_1, c_signal_1; // node 1 commutation channels
    chan c_pwm_ctrl_1, c_adctrig_1; // node 1 pwm channels
    chan c_torque_ctrl_1; // node 1 torque control channel
    chan c_watchdog_1; // node 1 WDT channel
    chan c_adc_1;//node 1 adc channel

    chan c_qei_p1_2, c_qei_p2_2, c_qei_p3_2; // node 2 qei channels
    chan c_hall_p1_2, c_hall_p2_2, c_hall_p3_2, c_hall_p4_2, c_hall_p5_2,
            c_hall_p6_2; // node 2 hall channels
    chan c_commutation_p1_2, c_commutation_p2_2, c_commutation_p3_2, c_signal_2; // node 2 commutation channels
    chan c_pwm_ctrl_2, c_adctrig_2; // node 2 pwm channels
    chan c_torque_ctrl_2; // node 2 torque control channel
    chan c_watchdog_2; // node 2 WDT channel
    chan c_adc_2;//node 2 adc channel

    chan c_qei_p1_3, c_qei_p2_3, c_qei_p3_3; // node 3 qei channels
    chan c_hall_p1_3, c_hall_p2_3, c_hall_p3_3, c_hall_p4_3, c_hall_p5_3,
            c_hall_p6_3; // node 3 hall channels
    chan c_commutation_p1_3, c_commutation_p2_3, c_commutation_p3_3, c_signal_3; // node 3 commutation channels
    chan c_pwm_ctrl_3, c_adctrig_3; // node 3 pwm channels
    chan c_torque_ctrl_3; // node 3 velocity control channel
    chan c_watchdog_3; // node 3 WDT channel
    chan c_adc_3;//node 2 adc channel

	    par
	        {
                //COMmunication - C22 node 0
                on tile[NODE_0_COM_TILE]:{

                    ecat_init();
                    ecat_handler(coe_out, coe_in, eoe_out, eoe_in, eoe_sig, foe_out,
                                            foe_in, pdo_out, pdo_in);
                }

                // Ethercat Motor Drive Loop
                on tile[NODE_0_APP_TILE_1] :
                {

                    ecat_motor_drive(pdo_out, pdo_in, coe_out, c_signal, c_hall_p5, c_qei_p5,
                                     c_torque_ctrl, c_velocity_ctrl, c_position_ctrl, c_gpio_p1);
                }

	            //APP - C22 node 0
	            on tile[NODE_0_APP_TILE_2]:
	            {
	                //delay_seconds(4);
	                par {

                            {
                                ctrl_par position_ctrl_params;
                                hall_par hall_params;
                                qei_par qei_params;

                                init_position_control_param(position_ctrl_params);
                                init_hall_param(hall_params);
                                init_qei_param(qei_params);

                                position_control(position_ctrl_params, hall_params, qei_params,\
                                                 SENSOR_USED, c_hall_p4, c_qei_p4, c_position_ctrl, c_commutation_p3);
                            }

                            // Velocity Control Loop
                            {
                                ctrl_par velocity_ctrl_params;
                                filter_par sensor_filter_params;
                                hall_par hall_params;
                                qei_par qei_params;

                                init_velocity_control_param(velocity_ctrl_params);
                                init_sensor_filter_param(sensor_filter_params);
                                init_hall_param(hall_params);
                                init_qei_param(qei_params);

                                velocity_control(velocity_ctrl_params, sensor_filter_params, hall_params,\
                                                 qei_params, SENSOR_USED, c_hall_p3, c_qei_p3, c_velocity_ctrl, c_commutation_p2);
                            }

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
                                        c_adc, c_commutation_p1,  c_hall_p2,  c_qei_p2, c_torque_ctrl);
                            }
	                }
	            }

	            //IFM - C22 node 0
	            on tile[NODE_0_IFM_TILE]:
	            {
                    par
	                {
                        // ADC loop
                        adc_ad7949_triggered(c_adc, c_adctrig, clk_adc,
                                             p_ifm_adc_sclk_conv_mosib_mosia_0, p_ifm_adc_miso_0,
                                             p_ifm_adc_conv_0);

                        // PWM Loop
                        do_pwm_inv_triggered(c_pwm_ctrl, c_adctrig, p_ifm_dummy_port_0,
                                             p_ifm_motor_hi_0, p_ifm_motor_lo_0, clk_pwm);

                        // Motor Commutation loop
                        {
                            hall_par hall_params;
                            qei_par qei_params;
                            commutation_par commutation_params;
                            commutation_sinusoidal(c_hall_p1,  c_qei_p1, c_signal, c_watchdog,
                                                   c_commutation_p1, c_commutation_p2, c_commutation_p3, c_pwm_ctrl,
                                                   p_ifm_esf_rstn_pwml_pwmh_0, p_ifm_coastn_0, p_ifm_ff1_0, p_ifm_ff2_0,
                                                   hall_params, qei_params, commutation_params);   // channel priority 1,2,3
                        }

                        // Watchdog Server
                        run_watchdog(c_watchdog, p_ifm_wd_tick_0, p_ifm_shared_leds_wden_0);

                        // GPIO Digital Server
                        gpio_digital_server(p_ifm_ext_d_0, c_gpio_p1, c_gpio_p2);

                        // Hall Server
                        {
                            hall_par hall_params;
                            run_hall(c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5,\
                                     c_hall_p6, p_ifm_hall_0, hall_params);    // channel priority 1,2..6
                        }

                        // QEI Server
                        {
                            qei_par qei_params;
                            run_qei(c_qei_p1, c_qei_p2, c_qei_p3, c_qei_p4, c_qei_p5, c_qei_p6,\
                                    p_ifm_encoder_btn2_0, qei_params);             // channel priority 1,2..6
                        }

	                }
	            }

	            //APP - C21 node 1
	            on tile[NODE_1_APP_TILE]:
	            {

	                par {
                            {
                                //printstrln("I am 1");
                                delay_seconds(2);
                           //     profile_torque_test(c_torque_ctrl_1);
                            }

                            // Torque Control Loop
                           {
                                ctrl_par torque_ctrl_params_1;
                                filter_par sensor_filter_params_1;
                                hall_par hall_params_1;
                                qei_par qei_params_1;

                                init_torque_control_param(torque_ctrl_params_1);

                                init_hall_param(hall_params_1);
                                init_qei_param(qei_params_1);

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

                            { delay_seconds(2);
                                //printstrln("I am 2");
                                delay_seconds(1);
                                profile_torque_test(c_torque_ctrl_2);
                            }

                             // Torque Control Loop
                            {
                                ctrl_par torque_ctrl_params_2;
                                filter_par sensor_filter_params_2;
                                hall_par hall_params_2;
                                qei_par qei_params_2;

                                init_torque_control_param(torque_ctrl_params_2);

                                init_hall_param(hall_params_2);
                                init_qei_param(qei_params_2);

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

                //APP - C21 node 3
                on tile[NODE_3_APP_TILE]:
                {
                    par {

                            {
                                //printstrln("I am 3");
                                delay_seconds(0);
                                //profile_velocity_test(c_velocity_ctrl_2, c_hall_p4_2);
                              //  profile_torque_test(c_torque_ctrl_3);
                            }

                              // Torque Control Loop
                            {
                                ctrl_par torque_ctrl_params_3;
                                filter_par sensor_filter_params_3;
                                hall_par hall_params_3;
                                qei_par qei_params_3;

                                init_torque_control_param(torque_ctrl_params_3);

                                init_hall_param(hall_params_3);
                                init_qei_param(qei_params_3);

                                torque_control( torque_ctrl_params_3, hall_params_3, qei_params_3, SENSOR_USED,
                                        c_adc_3, c_commutation_p1_3,  c_hall_p3_3,  c_qei_p3_3, c_torque_ctrl_3);
                            }
                    }
                }

                //IFM - C21 node 3
                on tile[NODE_3_IFM_TILE]:
                {
                    par
                    {
                        // ADC Loop
                        adc_ad7949_triggered(c_adc_3, c_adctrig_3, clk_adc_3, p_ifm_adc_sclk_conv_mosib_mosia_3, p_ifm_adc_miso_3,
                                p_ifm_adc_conv_3);

                        // PWM Loop
                        do_pwm_inv_triggered(c_pwm_ctrl_3, c_adctrig_3,
                                p_ifm_dummy_port_3, p_ifm_motor_hi_3, p_ifm_motor_lo_3,
                                clk_pwm_3);

                        // Motor Commutation loop
                        {
                            hall_par hall_params_3;
                            qei_par qei_params_3;
                            commutation_par commutation_params_3;
                            int init_state;
                            init_hall_param(hall_params_3);
                            init_qei_param(qei_params_3);
                            commutation_sinusoidal(c_hall_p1_3, c_qei_p1_3, c_signal_3,
                                    c_watchdog_3, c_commutation_p1_3,
                                    c_commutation_p2_3, c_commutation_p3_3,
                                    c_pwm_ctrl_3, p_ifm_esf_rstn_pwml_pwmh_3,
                                    p_ifm_coastn_3, p_ifm_ff1_3, p_ifm_ff2_3,
                                    hall_params_3, qei_params_3, commutation_params_3);
                        }

                        // Watchdog Server
                        run_watchdog(c_watchdog_3, p_ifm_wd_tick_3,
                                p_ifm_shared_leds_wden_3);

                        // Hall Server
                        {
                            hall_par hall_params_3;
                            run_hall(c_hall_p1_3, c_hall_p2_3, c_hall_p3_3,
                                    c_hall_p4_3, c_hall_p5_3, c_hall_p6_3,
                                    p_ifm_hall_3, hall_params_3);
                        }
                    }
                }
	        }

	return 0;
}
