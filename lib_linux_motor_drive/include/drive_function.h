
/**
 * @file drive_function.h
 * @brief Motor Drive functions over Ethercat
 * @author Pavan Kanajar <pkanajar@synapticon.com>
 */

#include <drive_config.h>
#include <ctrlproto_m.h>
#include <profile.h>

#ifdef __cplusplus
extern "C" {
#endif
	/**
	 * @brief Initialise Linear Profile
	 *
	 *  Input
	 * @param target_value
	 * @param actual_value
	 * @param acceleration for the Linear profile
	 * @param deceleration for the Linear profile
	 * @param max_value for the Linear profile
	 * @param profile_linear_params struct for profile parameters
	 *
	 * Output
	 * @return no. of steps for linear profile : range [1 - steps-1]
	 */
	extern int init_linear_profile_float(float target_value, float actual_value, float acceleration, \
			float deceleration, float max_value, profile_linear_param *profile_linear_params);

	/**
	 * @brief Generate Linear Profile
	 *
	 *  Input
	 * @param step current step of the profile
	 * @param profile_linear_params struct for profile parameters
	 *
	 * Output
	 * @return corresponding target value at the step input
	 */
	extern float linear_profile_generate_float(int step, profile_linear_param *profile_linear_params);

#ifdef __cplusplus
}
#endif



/**
 * @brief Initialize all connected nodes with basic motor configurations via bldc_motor_config headers
 *
 * @param master_setup          A struct containing the variables for the master
 * @param slv_handles           The handle struct for the slaves
 * @param total_no_of_slaves    Number of connected slaves to the master
 */
void init_nodes(master_setup_variables_t *master_setup, ctrlproto_slv_handle *slv_handles, int total_no_of_slaves);

/**
 * @brief Start Homing
 *
 *
 * @param master_setup 			A struct containing the variables for the master
 * @param slv_handles 			The handle struct for the slaves
 * @param home_velocity 		Velocity used for homing mode
 * @param home_acceleration 	Acceleration used for homing mode
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param total_no_of_slaves 	Number of connected slaves to the master
 *
 */
void start_homing(master_setup_variables_t *master_setup, ctrlproto_slv_handle *slv_handles,\
		int home_velocity, int home_acceleration, int slave_number, int total_no_of_slaves);



/**
 * @brief Sets operation mode via defines for modes of operation in drive_config.h
 *
 * @param operation_mode        Specify the operation mode for the slave
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param master_setup 			A struct containing the variables for the master
 * @param slv_handles 			The handle struct for the slaves
 * @param total_no_of_slaves 	Number of connected slaves to the master
 */
int set_operation_mode(int operation_mode, int slave_number, master_setup_variables_t *master_setup,\
		ctrlproto_slv_handle *slv_handles, int total_no_of_slaves);


/**
 * @brief Enables the operation mode specified
 *
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param master_setup 			A struct containing the variables for the master
 * @param slv_handles 			The handle struct for the slaves
 * @param total_no_of_slaves 	Number of connected slaves to the master
 */
int enable_operation(int slave_number, master_setup_variables_t *master_setup, \
		ctrlproto_slv_handle *slv_handles, int total_no_of_slaves);


/**
 * @brief Shuts down the operation mode selected
 *
 * @param operation_mode        Specify the operation mode selected for the slave
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param master_setup 			A struct containing the variables for the master
 * @param slv_handles 			The handle struct for the slaves
 * @param total_no_of_slaves 	Number of connected slaves to the master
 */
int shutdown_operation(int operation_mode, int slave_number, master_setup_variables_t *master_setup, \
		ctrlproto_slv_handle *slv_handles, int total_no_of_slaves);


/**
 * @brief Sets target position cyclically for Cyclic Synchronous Position(CSP) mode only
 *
 * @param target_position 		Specify the target position to follow (in ticks)
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param slv_handles 			The handle struct for the slaves
 */
void set_position_ticks(int target_position, int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Sets target position for Profile Position mode(PPM) only
 *
 * @param target_position		Specify the target position to follow (in ticks)
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param slv_handles 			The handle struct for the slaves
 */
void set_profile_position_ticks(int target_position, int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Gets actual position
 *
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param slv_handles 			The handle struct for the slaves
 *
 * @return actual_position (ticks) from the slave number specified
 */
int get_position_actual_ticks(int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Quick Stop Position
 *
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param master_setup 			A struct containing the variables for the master
 * @param slv_handles 			The handle struct for the slaves
 * @param total_no_of_slaves 	Number of connected slaves to the master
 */
int quick_stop_position(int slave_number, master_setup_variables_t *master_setup, ctrlproto_slv_handle *slv_handles, int total_no_of_slaves);


/**
 * @brief Check target position reached for Profile position mode
 *
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param target_position		Specify the target position set (in ticks)
 * @param tolerance 			Specify the tolerance for target position (in ticks)
 * @param slv_handles 			The handle struct for the slaves
 *
 * @return 1 if target position reached else 0
 */
int target_position_reached(int slave_number, int target_position, int tolerance, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Initialise Position Profile Limits
 *
 *  Input
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param slv_handles 			The handle struct for the slaves
 *
 */
void initialize_position_profile_limits(int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Initialize Position Profile parameters
 *
 * @param target_position		Specify the target position to follow (in ticks)
 * @param actual_position		Specify the actual position (in ticks)
 * @param velocity				Specify the velocity (in rpm)
 * @param acceleration			Specify the acceleration (in rpm/s)
 * @param deceleration			Specify the deceleration (in rpm/s)
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param slv_handles 			The handle struct for the slaves
 *
 */
int init_position_profile_params(int target_position, int actual_position, int velocity, \
		int acceleration, int deceleration, int slave_number, ctrlproto_slv_handle *slv_handles);

/**
 * @brief Generate Position Profile
 *
 *  Input
 * @param step current step of the profile
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param slv_handles 			The handle struct for the slaves
 *
 * Output
 * @return corresponding target position at the step input : range [1 - steps-1]
 */
int generate_profile_position(int step, int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Sets target torque for Profile Torque mode(PTM) & Cyclic Synchronous Torque(CST) mode
 *
 * @param target_torque			Specify the target torque to follow (in mNm)
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param slv_handles 			The handle struct for the slaves
 */
void set_torque_mNm(float target_torque, int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Gets actual torque
 *
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param slv_handles 			The handle struct for the slaves
 *
 * @return actual torque in mNm from the slave number specified
 */
float get_torque_actual_mNm(int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Check target torque reached for Profile torque Mode
 *
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param target_torque			Specify the target torque set (in mNm)
 * @param tolerance 			Specify the tolerance for target torque (in mNm)
 * @param slv_handles 			The handle struct for the slaves
 *
 * @return 1 if target torque reached else 0
 */
int target_torque_reached(int slave_number, float target_torque, float tolerance, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Initialize Torque parameters for Profile Torque mode(PTM) & Cyclic Synchronous Torque(CST) mode
 *
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param slv_handles 			The handle struct for the slaves
 *
 */
void initialize_torque(int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Initialize Linear Profile parameters for Profile torque mode
 *
 * @param target_torque			Specify the target torque to follow (in mNm)
 * @param actual_torque			Specify the actual torque (in mNm)
 * @param torque_slope			Specify the torque slope (in mNm/s)
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param slv_handles 			The handle struct for the slaves
 *
 */
int init_linear_profile_params(float target_torque, float actual_torque, float torque_slope, int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Generate Linear Profile
 *
 *  Input
 * @param step current step of the profile
 *
 * Output
 * @return corresponding target value at the step input : range [1 - steps-1]
 */
float generate_profile_linear(int step, int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Quick Stop Torque
 *
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param master_setup 			A struct containing the variables for the master
 * @param slv_handles 			The handle struct for the slaves
 * @param total_no_of_slaves 	Number of connected slaves to the master
 */
int quick_stop_torque(int slave_number, master_setup_variables_t *master_setup, ctrlproto_slv_handle *slv_handles, int total_no_of_slaves);


/**
 * @brief Sets target velocity for Profile Velocity mode(PPM) & Cyclic Synchronous Velocity(CSV) mode
 *
 * @param target_velocity		Specify the target velocity to follow (in rpm)
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param slv_handles 			The handle struct for the slaves
 */
void set_velocity_rpm(int target_velocity, int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Gets actual velocity
 *
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param slv_handles 			The handle struct for the slaves
 *
 * @return actual_velocity in rpm from the slave number specified
 */
int get_velocity_actual_rpm(int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Quick Stop Velocity
 *
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param master_setup 			A struct containing the variables for the master
 * @param slv_handles 			The handle struct for the slaves
 * @param total_no_of_slaves 	Number of connected slaves to the master
 */
int quick_stop_velocity(int slave_number, master_setup_variables_t *master_setup, ctrlproto_slv_handle *slv_handles, int total_no_of_slaves);


/**
 * @brief Check target velocity reached for Profile velocity Mode
 *
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param target_velocity		Specify the target velocity set (in rpm)
 * @param tolerance 			Specify the tolerance for target velocity
 * @param slv_handles 			The handle struct for the slaves
 */
int target_velocity_reached(int slave_number, int target_velocity, int tolerance, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Initialise Velocity Profile
 *
 *  Input
 * @param target_velocity
 * @param actual_velocity
 * @param acceleration for the velocity profile
 * @param deceleration for the velocity profile
 * @param max_velocity for the velocity profile
 * @param slave_number	Specify the slave number to which the motor is connected
 * @param slv_handles 	The handle struct for the slaves
 *
 * Output
 * @return no. of steps for velocity profile
 */
int init_velocity_profile_params(int target_velocity, int actual_velocity, int acceleration, \
		int deceleration, int slave_number, ctrlproto_slv_handle *slv_handles);

/**
 * @brief Generate Velocity Profile
 *
 *  Input
 * @param step current step of the profile
 * @param slave_number Specify the slave number to which the motor is connected
 * @param slv_handles The handle struct for the slaves
 *
 * Output
 * @return corresponding target velocity at the step input : range [1 - steps-1]
 */
int generate_profile_velocity(int step, int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Check velocity set for Profile velocity mode
 *
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param slv_handles 			The handle struct for the slaves
 */
int velocity_set_flag(int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Check position set for Profile position mode
 *
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param slv_handles 			The handle struct for the slaves
 */
int position_set_flag(int slave_number, ctrlproto_slv_handle *slv_handles);


/**
 * @brief Enable control after quick stop operation
 *
 * @param operation_mode        Specify the operation mode selected for the slave
 * @param slave_number			Specify the slave number to which the motor is connected
 * @param master_setup 			A struct containing the variables for the master
 * @param slv_handles 			The handle struct for the slaves
 * @param total_no_of_slaves 	Number of connected slaves to the master
 */
int renable_ctrl_quick_stop(int operation_mode, int slave_number, master_setup_variables_t *master_setup, ctrlproto_slv_handle *slv_handles, int total_no_of_slaves);


/*Internal Function */
int position_limit(int target_position, int slave_number, ctrlproto_slv_handle *slv_handles);


int check_home_active(int status_word);
