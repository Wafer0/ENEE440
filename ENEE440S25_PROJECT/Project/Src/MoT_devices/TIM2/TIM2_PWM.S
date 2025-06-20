#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

.syntax unified
.thumb

.text

@======================================================================
@ device6_pwm_enable: Configures and enables TIM2 Channel 1 for PWM output.
@ This function sets up Timer 2 (TIM2) to generate a Pulse Width Modulated (PWM)
@ signal on Channel 1 (GPIO PA5).
@ It uses global variables 'pwm_arr_val' for the Auto-Reload Register (ARR) value,
@ which determines the PWM period, and 'pwm_arr_duty' for the duty cycle
@ percentage (0-100).
@ The function performs the following steps:
@ 1. Disables any current TIM2 output by calling 'device6_timer_output_disable'.
@ 2. Disables the TIM2 counter (CEN bit in TIMx_CR1) before full configuration.
@ 3. Calculates and sets the TIM2 Prescaler (TIMx_PSC) to achieve the
@    TARGET_TIM_CLOCK_HZ (e.g., 1MHz) based on ACTUAL_PCLK1_HZ.
@ 4. Sets the TIM2 Auto-Reload Register (TIMx_ARR) with the value from 'pwm_arr_val'.
@ 5. Calculates the TIM2 Capture/Compare Register 1 (TIMx_CCR1) value based on
@    the ARR and the duty cycle percentage from 'pwm_arr_duty'.
@    CCR1 = (pwm_arr_duty * ARR) / 100.
@ 6. Configures TIM2 Channel 1 in Capture/Compare Mode Register 1 (TIMx_CCMR1)
@    for PWM Mode 1 (output active while CNT < CCR1) and enables preload for CCR1.
@ 7. Configures TIM2 Capture/Compare Enable Register (TIMx_CCER) to enable
@    Channel 1 output with active high polarity.
@ 8. Enables Auto-Reload Preload for ARR in TIMx_CR1 (ARPE bit).
@ 9. Generates an update event (UG bit in TIMx_EGR) to load the prescaler,
@    ARR, and CCR1 values from their preload registers into the active registers.
@ 10. Enables the TIM2 counter (CEN bit in TIMx_CR1) to start PWM generation.
@======================================================================
.global device6_pwm_enable
.thumb_func
device6_pwm_enable:
    push {r0-r7, lr}
	bl device6_timer_output_disable
    MOV_imm32 r0, TIM2_BASE

    ldr r1, [r0, #TIMx_CR1]
    bic r1, r1, #TIMx_CR1_CEN
    str r1, [r0, #TIMx_CR1]

    movw r1, #:lower16:(ACTUAL_PCLK1_HZ / TARGET_TIM_CLOCK_HZ - 1)
    movt r1, #:upper16:(ACTUAL_PCLK1_HZ / TARGET_TIM_CLOCK_HZ - 1)
    str r1, [r0, #TIMx_PSC]

    ldr r2, =pwm_arr_val
    ldr r1, [r2]
    str r1, [r0, #TIMx_ARR]

	ldr r2, =pwm_arr_duty
	ldr r2, [r2]
	mul r2, r2, r1
	movs r3, #100
	udiv r2, r2, r3
    str r2, [r0, #TIMx_CCR1]

    ldr r1, [r0, #TIMx_CCMR1]
    movs r2, #0x73
    bic r1, r1, r2
    orr r1, r1, #TIMx_CCMR1_OC1M_PWM1
    orr r1, r1, #TIMx_CCMR1_OC1PE
    str r1, [r0, #TIMx_CCMR1]

    ldr r1, [r0, #TIMx_CCER]
    bic r1, r1, #(1 << 1)
    orr r1, r1, #TIMx_CCER_CC1E
    str r1, [r0, #TIMx_CCER]

    ldr r1, [r0, #TIMx_CR1]
    orr r1, r1, #TIMx_CR1_ARPE
    str r1, [r0, #TIMx_CR1]

    movs r2, #TIMx_EGR_UG
    str r2, [r0, #TIMx_EGR]

    ldr r1, [r0, #TIMx_CR1]
    orr r1, r1, #TIMx_CR1_CEN
    str r1, [r0, #TIMx_CR1]

    pop {r0-r7, pc}
