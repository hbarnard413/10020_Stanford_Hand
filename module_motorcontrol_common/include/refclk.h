/**
 * @file refclk.h
 * @brief Reference Clock definitions
 * @author Martin Schwarz <mschwarz@synapticon.com>
 */


#pragma once

#include <xs1.h>

/* 10NSEC_STD --> 1 */
#define USEC_STD       100
#define MSEC_STD    100000
#define SEC_STD  100000000


#if PLATFORM_REFERENCE_MHZ == 100

#define USEC_FAST USEC_STD
#define MSEC_FAST MSEC_STD
#define SEC_FAST  SEC_STD

#else /* REFCLK_STD == 100 MHZ , REFCLK_FAST == 250 MHZ */


/* 4NSEC_FAST --> 1 */
#define USEC_FAST       250
#define MSEC_FAST    250000
#define SEC_FAST  250000000

#endif

/**
 * @brief Delay function in microseconds
 *
 * @Input
 * @param microseconds specify the delay in microseconds
 * @param core_id specify the core number in which the function is called
 * @param t timer used to calculate the microseconds elapsed
 */
void wait_micro_s(unsigned microseconds, int core_id, timer t);

/**
 * @brief Delay function in milliseconds
 *
 * @Input
 * @param milliseconds specify the delay in milliseconds
 * @param core_id specify the core number in which the function is called
 * @param t timer used to calculate the milliseconds elapsed
 */
void wait_ms(unsigned milliseconds, int core_id, timer t);


/**
 * @brief Delay function in seconds
 *
 * @Input
 * @param seconds specify the delay in seconds
 * @param core_id specify the core number in which the function is called
 * @param t timer used to calculate the seconds elapsed
 */
void wait_s(unsigned seconds, int core_id, timer t);
