#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

.syntax unified
.thumb

.text

@======================================================================
@ device6_opm_enable: Configures and starts TIM2_CH1 for One-Pulse Mode (OPM) with delay.
@ This function generates a single pulse on TIM2_CH1 (PA5) after a specified
@ initial delay. The delay and pulse width are provided by global variables
@ 'opm_delay_ticks_val' and 'opm_width_ticks_val' respectively (in timer ticks).
@ Operations:
@ 1. Disables any current TIM2 output using 'device6_timer_output_disable'.
@ 2. Loads delay and width values. Ensures they are not negative.
@ 3. Sets TIM2 Prescaler (PSC) to achieve TARGET_TIM_CLOCK_HZ (e.g., 1MHz).
@ 4. Configures TIM2_CCR1 with the delay value (pulse starts when CNT reaches CCR1).
@ 5. Configures TIM2_ARR with (delay + width) (pulse ends and timer stops when CNT reaches ARR).
@ 6. Sets TIM2_CCMR1 for PWM Mode 2 (output inactive then active) and enables CCR1 preload.
@ 7. Sets TIM2_CCER for Channel 1 output, active high polarity.
@ 8. Sets TIM2_CR1 for One-Pulse Mode (OPM) and Auto-Reload Preload Enable (ARPE).
@ 9. Generates an update event (TIMx_EGR_UG) to load shadow registers.
@ 10. Enables the TIM2 counter (TIMx_CR1_CEN).
@======================================================================
.global device6_opm_enable
.thumb_func
device6_opm_enable:
    push {r0-r7, lr}

    bl device6_timer_output_disable

    ldr r2, =opm_delay_ticks_val
    ldr r4, [r2]
    ldr r2, =opm_width_ticks_val
    ldr r5, [r2]

    MOV_imm32 r0, TIM2_BASE

    movw r1, #:lower16:(ACTUAL_PCLK1_HZ / TARGET_TIM_CLOCK_HZ - 1)
    movt r1, #:upper16:(ACTUAL_PCLK1_HZ / TARGET_TIM_CLOCK_HZ - 1)
    str r1, [r0, #TIMx_PSC]

    cmp r4, #0
    it lt
    movlt r4, #0
    cmp r5, #0
    it lt
    movlt r5, #0

    str r4, [r0, #TIMx_CCR1]

    add r1, r4, r5
    str r1, [r0, #TIMx_ARR]

    ldr r1, [r0, #TIMx_CCMR1]
    movs r2, #0x73
    bic r1, r1, r2
    movs r2, #(0b111 << 4)
    orr r1, r1, r2
    orr r1, r1, #TIMx_CCMR1_OC1PE
    str r1, [r0, #TIMx_CCMR1]

    ldr r1, [r0, #TIMx_CCER]
    bic r1, r1, #(1 << 1)
    orr r1, r1, #TIMx_CCER_CC1E
    str r1, [r0, #TIMx_CCER]

    ldr r1, [r0, #TIMx_CR1]
    orr r1, r1, #TIMx_CR1_ARPE
    orr r1, r1, #TIMx_CR1_OPM
    str r1, [r0, #TIMx_CR1]

    movs r2, #TIMx_EGR_UG
    str r2, [r0, #TIMx_EGR]
    ldr r1, [r0, #TIMx_CR1]
    orr r1, r1, #TIMx_CR1_CEN
    str r1, [r0, #TIMx_CR1]
    pop {r0-r7, pc}

@======================================================================
@ device6_simple_pulse_enable: Generates a single pulse with a fixed minimal delay.
@ This function acts as a wrapper for 'device6_opm_enable'. It reads the desired
@ pulse width (in timer ticks) from the global variable 'simple_pulse_width_ticks_val'.
@ It then sets a small, fixed delay (10 ticks) and calls 'device6_opm_enable'
@ to produce the pulse on TIM2_CH1 (PA5).
@ This is used for the "Simple Pulse On" functionality (Device 6, Cmd 0x03).
@ Input: Relies on 'simple_pulse_width_ticks_val' being pre-loaded.
@======================================================================
.global device6_simple_pulse_enable
.thumb_func
device6_simple_pulse_enable:
    push {r0-r7, lr}

	ldr r0, =simple_pulse_width_ticks_val
	ldr r0, [r0]

	ldr r1, =opm_width_ticks_val
	str r0, [r1]

	ldr r1, =opm_delay_ticks_val
	mov r0, #10
	str r0, [r1]

	bl device6_opm_enable

    pop {r0-r7, pc}

@======================================================================
@ device6_single_freq_cycle_enable: Generates a single cycle of a square wave at a given frequency.
@ This function produces one complete pulse (50% duty cycle) at a target frequency
@ specified by the global variable 'single_freq_cycle_target_hz_val', then stops due to OPM.
@ Used for "Pulse Frequency On" (Device 6, Cmd 0x05).
@ Operations:
@ 1. Disables any current TIM2 output.
@ 2. Loads the target frequency.
@ 3. Sets TIM2 Prescaler for TARGET_TIM_CLOCK_HZ (e.g., 1MHz).
@ 4. Calculates ARR for one period: (TARGET_TIM_CLOCK_HZ / target_freq_hz) - 1.
@ 5. Calculates CCR1 for 50% duty cycle: (ARR + 1) / 2.
@ 6. Configures TIM2_CCMR1 for PWM Mode 1 and enables CCR1 preload.
@ 7. Configures TIM2_CCER for Channel 1 output, active high.
@ 8. Configures TIM2_CR1 for One-Pulse Mode (OPM) and ARPE.
@ 9. Generates an update event and enables the TIM2 counter.
@ Handles division by zero if target frequency is 0.
@======================================================================
.global device6_single_freq_cycle_enable
.thumb_func
device6_single_freq_cycle_enable:
    push {r0-r7, lr}

    bl device6_timer_output_disable

    ldr r3, =single_freq_cycle_target_hz_val
    ldr r3, [r3]

    MOV_imm32 r0, TIM2_BASE

    movw r1, #:lower16:(ACTUAL_PCLK1_HZ / TARGET_TIM_CLOCK_HZ - 1)
    movt r1, #:upper16:(ACTUAL_PCLK1_HZ / TARGET_TIM_CLOCK_HZ - 1)
    str r1, [r0, #TIMx_PSC]

    ldr r4, =TARGET_TIM_CLOCK_HZ
    cmp r3, #0
    beq err
    udiv r4, r4, r3
    subs r4, r4, #1
    str r4, [r0, #TIMx_ARR]

    mov r5, r4
    add r5, r5, #1
    lsrs r5, r5, #1
    str r5, [r0, #TIMx_CCR1]

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
    orr r1, r1, #TIMx_CR1_OPM
    str r1, [r0, #TIMx_CR1]

    movs r2, #TIMx_EGR_UG
    str r2, [r0, #TIMx_EGR]

    ldr r1, [r0, #TIMx_CR1]
    orr r1, r1, #TIMx_CR1_CEN
    str r1, [r0, #TIMx_CR1]

done:
    pop {r0-r7, pc}

err:
    b done
