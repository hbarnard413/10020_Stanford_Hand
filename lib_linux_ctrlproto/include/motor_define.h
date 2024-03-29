
/**
 * @file motor_define.h
 * @brief Motor Config Struct definitions
 * @author Pavan Kanajar <pkanajar@synapticon.com>
 */

#ifndef MOTOR_DEFINE_H_
#define MOTOR_DEFINE_H_

#ifdef __cplusplus
extern "C"
{
#endif

	typedef struct
	{
		int pole_pair;
		int update_state;
	} pole_pair_s;

typedef struct
{
	int gear_ratio;
	int update_state;
} gear_ratio_s;

typedef struct
{
	int nominal_motor_speed;
	int update_state;
} nominal_motor_speed_s;

typedef struct
{
	int nominal_current;
	int update_state;
} nominal_current_s;

typedef struct
{
	int max_acceleration;
	int update_state;
} max_acceleration_s;

typedef struct
{
	int position_encoder_resolution;
	int update_state;
} position_encoder_resolution_s;

typedef struct
{
	int polarity;
	int update_state;
} polarity_s;

typedef struct
{
	int sensor_selection_code;
	int update_state;
} sensor_selection_code_s;

typedef struct
{
	int p_gain;
	int update_state;
} velocity_p_gain_s, position_p_gain_s, torque_p_gain_s;

typedef struct
{
	int i_gain;
	int update_state;
} velocity_i_gain_s, position_i_gain_s, torque_i_gain_s;

typedef struct
{
	int d_gain;
	int update_state;
} velocity_d_gain_s, position_d_gain_s, torque_d_gain_s;

typedef struct
{
	int software_position_min;
	int update_state;
} software_position_min_s;

typedef struct
{
	int software_position_max;
	int update_state;
} software_position_max_s;


typedef struct
{
	int max_profile_velocity;
	int update_state;
} max_profile_velocity_s;

typedef struct
{
	int profile_acceleration;
	int update_state;
} profile_acceleration_s;

typedef struct
{
	int profile_deceleration;
	int update_state;
} profile_deceleration_s;

typedef struct
{
	int quick_stop_deceleration;
	int update_state;
} quick_stop_deceleration_s;

typedef struct
{
	int profile_velocity;
	int update_state;
} profile_velocity_s;

typedef struct
{
	int max_torque;
	int update_state;
} max_torque_s;

typedef struct
{
	int torque_slope;
	int update_state;
} torque_slope_s;

typedef struct
{
	int motor_torque_constant;
	int update_state;
} motor_torque_constant_s;

typedef struct
{
	int qei_offset_clk;
	int update_state;
} qei_offset_clk_s;

typedef struct
{
	int qei_offset_cclk;
	int update_state;
} qei_offset_cclk_s;

typedef struct
{
	int qei_commutation_offset_clk;
	int update_state;
} qei_commutation_offset_clk_s;

typedef struct
{
	int qei_commutation_offset_cclk;
	int update_state;
} qei_commutation_offset_cclk_s;

typedef struct
{
	int commutation_offset_clk;
	int update_state;
} commutation_offset_clk_s;

typedef struct
{
	int commutation_offset_cclk;
	int update_state;
} commutation_offset_cclk_s;

typedef struct
{
	int motor_winding_type;
	int update_state;
} motor_winding_type_s;

typedef struct
{
	int limit_switch_type;
	int update_state;
} limit_switch_type_s;

typedef struct
{
	int homing_method;
	int update_state;
} homing_method_s;

typedef struct
{
	int sensor_polarity;
	int update_state;
} sensor_polarity_s;

typedef struct
{
	pole_pair_s s_pole_pair;
	gear_ratio_s s_gear_ratio;
	nominal_motor_speed_s s_nominal_motor_speed;
	nominal_current_s s_nominal_current;
	motor_torque_constant_s s_motor_torque_constant;
	max_acceleration_s s_max_acceleration;
	position_encoder_resolution_s s_position_encoder_resolution; //qei

	polarity_s s_polarity;
	sensor_selection_code_s s_sensor_selection_code; //hall/qei/...

	velocity_p_gain_s s_velocity_p_gain;
	velocity_i_gain_s s_velocity_i_gain;
	velocity_d_gain_s s_velocity_d_gain;

	position_p_gain_s s_position_p_gain;
	position_i_gain_s s_position_i_gain;
	position_d_gain_s s_position_d_gain;

	torque_p_gain_s s_torque_p_gain;
	torque_i_gain_s s_torque_i_gain;
	torque_d_gain_s s_torque_d_gain;

	software_position_min_s s_software_position_min;
	software_position_max_s s_software_position_max;

	max_torque_s s_max_torque;
	torque_slope_s s_torque_slope;
	max_profile_velocity_s s_max_profile_velocity;
	profile_acceleration_s s_profile_acceleration;
	profile_deceleration_s s_profile_deceleration;
	quick_stop_deceleration_s s_quick_stop_deceleration;
	profile_velocity_s s_profile_velocity;

	qei_offset_clk_s s_qei_offset_clk;
	qei_offset_cclk_s s_qei_offset_cclk;
	qei_commutation_offset_clk_s s_qei_commutation_offset_clk;
	qei_commutation_offset_cclk_s s_qei_commutation_offset_cclk;

	commutation_offset_clk_s s_commutation_offset_clk;
	commutation_offset_cclk_s s_commutation_offset_cclk;
	motor_winding_type_s s_motor_winding_type;

	limit_switch_type_s s_limit_switch_type;
	homing_method_s s_homing_method;
	sensor_polarity_s s_sensor_polarity;
	int update_flag;
} motor_config;

#define GEAR_RATIO(n) 				GEAR_RATIO_##n
#define MAX_ACCELERATION(n) 		MAX_ACCELERATION_##n
#define MAX_NOMINAL_CURRENT(n) 		MAX_NOMINAL_CURRENT_##n
#define MAX_NOMINAL_SPEED(n) 		MAX_NOMINAL_SPEED_##n
#define POLARITY(n) 				POLARITY_##n
#define POLE_PAIRS(n) 				POLE_PAIRS_##n
#define MOTOR_TORQUE_CONSTANT(n) 	MOTOR_TORQUE_CONSTANT_##n
#define ENCODER_RESOLUTION(n) 		ENCODER_RESOLUTION_##n
#define VELOCITY_Kp_NUMERATOR(n)   	VELOCITY_Kp_NUMERATOR_##n
#define VELOCITY_Kp_DENOMINATOR(n)  VELOCITY_Kp_DENOMINATOR_##n
#define VELOCITY_Ki_NUMERATOR(n)   	VELOCITY_Ki_NUMERATOR_##n
#define VELOCITY_Ki_DENOMINATOR(n)  VELOCITY_Ki_DENOMINATOR_##n
#define VELOCITY_Kd_NUMERATOR(n)  	VELOCITY_Kd_NUMERATOR_##n
#define VELOCITY_Kd_DENOMINATOR(n)  VELOCITY_Kd_DENOMINATOR_##n
#define SENSOR_SELECTION_CODE(n) 	SENSOR_SELECTION_CODE_##n

#define POSITION_Kp_NUMERATOR(n)   	POSITION_Kp_NUMERATOR_##n
#define POSITION_Kp_DENOMINATOR(n)  POSITION_Kp_DENOMINATOR_##n
#define POSITION_Ki_NUMERATOR(n)   	POSITION_Ki_NUMERATOR_##n
#define POSITION_Ki_DENOMINATOR(n)  POSITION_Ki_DENOMINATOR_##n
#define POSITION_Kd_NUMERATOR(n)  	POSITION_Kd_NUMERATOR_##n
#define POSITION_Kd_DENOMINATOR(n)  POSITION_Kd_DENOMINATOR_##n

#define TORQUE_Kp_NUMERATOR(n)   	TORQUE_Kp_NUMERATOR_##n
#define TORQUE_Kp_DENOMINATOR(n)  	TORQUE_Kp_DENOMINATOR_##n
#define TORQUE_Ki_NUMERATOR(n)   	TORQUE_Ki_NUMERATOR_##n
#define TORQUE_Ki_DENOMINATOR(n) 	TORQUE_Ki_DENOMINATOR_##n
#define TORQUE_Kd_NUMERATOR(n)  	TORQUE_Kd_NUMERATOR_##n
#define TORQUE_Kd_DENOMINATOR(n)  	TORQUE_Kd_DENOMINATOR_##n

#define MIN_POSITION_LIMIT(n)		MIN_POSITION_LIMIT_##n
#define MAX_POSITION_LIMIT(n)		MAX_POSITION_LIMIT_##n


#define MAX_TORQUE(n) 				MAX_TORQUE_##n
#define TORQUE_SLOPE(n) 			TORQUE_SLOPE_##n
#define MAX_PROFILE_VELOCITY(n)  	MAX_PROFILE_VELOCITY_##n
#define PROFILE_VELOCITY(n)			PROFILE_VELOCITY_##n
#define PROFILE_ACCELERATION(n)		PROFILE_ACCELERATION_##n
#define PROFILE_DECELERATION(n)  	PROFILE_DECELERATION_##n
#define QUICK_STOP_DECELERATION(n) 	QUICK_STOP_DECELERATION_##n

#define COMMUTATION_OFFSET_CLK(n) 	COMMUTATION_OFFSET_CLK_##n
#define COMMUTATION_OFFSET_CCLK(n) 	COMMUTATION_OFFSET_CCLK_##n
#define WINDING_TYPE(n) 			WINDING_TYPE_##n

#define HOMING_METHOD(n) 			HOMING_METHOD_##n
#define LIMIT_SWITCH_TYPES(n) 		LIMIT_SWITCH_TYPES_##n
#define QEI_SENSOR_POLARITY(n) 		QEI_SENSOR_POLARITY_##n

#ifdef __cplusplus
}
#endif

#endif
