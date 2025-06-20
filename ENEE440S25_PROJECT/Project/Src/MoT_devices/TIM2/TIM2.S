#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

.syntax unified
.thumb

.text

@======================================================================
@ device6_timer_base_init: Initializes TIM2 base and GPIO PA5 for TIM2_CH1.
@ This function performs the fundamental setup required for using TIM2 Channel 1
@ with GPIO pin PA5,  for timer output functionalities like PWM or OPM.
@ The operations include:
@ 1. Enabling the clock for GPIO Port A (GPIOAEN_BIT in RCC_AHB2ENR).
@ 2. Configuring GPIO PA5:
@    - Mode: Set to Alternate Function (0b10).
@    - Output Type: Set to Push-pull (0).
@    - Output Speed: Set to High speed (0b10).
@    - Pull-up/Pull-down: Configured to No pull-up, no pull-down (00).
@    - Alternate Function Mapping: AF1 (PA5_AF_TIM2_CH1) is selected to connect
@      PA5 to the TIM2_CH1 signal.
@ 3. Enabling the clock for the TIM2 peripheral (TIM2EN_BIT in RCC_APB1ENR1).
@    Includes nops for potential clock stabilization delay.
@ 4. Ensuring TIM2 counter (TIMx_CR1_CEN) and Channel 1 output (TIMx_CCER_CC1E)
@    are initially disabled. This leaves TIM2 in a known, inactive state, ready
@    for specific mode configuration (e.g., PWM, OPM).
@======================================================================
.global device6_timer_base_init
.thumb_func
device6_timer_base_init:
    push {r0-r3, lr}

    MOV_imm32 r0, RCC_BASE
    ldr r1, [r0, #RCC_AHB2ENR]
    orr r1, r1, #GPIOAEN_BIT
    str r1, [r0, #RCC_AHB2ENR]

    MOV_imm32 r0, GPIOA_BASE
    ldr r1, [r0, #GPIOA_MODER]
    bic r1, r1, #(0b11 << PA5_MODER_Pos)
    orr r1, r1, #(0b10 << PA5_MODER_Pos)
    str r1, [r0, #GPIOA_MODER]

    ldr r1, [r0, #GPIOA_OTYPER]
    bic r1, r1, #(1 << PA5_OTYPER_Pos)
    str r1, [r0, #GPIOA_OTYPER]

    ldr r1, [r0, #GPIOA_OSPEEDR]
    bic r1, r1, #(0b11 << PA5_OSPEEDR_Pos)
    orr r1, r1, #(0b10 << PA5_OSPEEDR_Pos)
    str r1, [r0, #GPIOA_OSPEEDR]

    ldr r1, [r0, #GPIOA_PUPDR]
    bic r1, r1, #(0b11 << PA5_PUPDR_Pos)
    str r1, [r0, #GPIOA_PUPDR]

    ldr r1, [r0, #GPIOA_AFRL]
    bic r1, r1, #(0b1111 << PA5_AFRL_Pos)
    orr r1, r1, #PA5_AF_TIM2_CH1
    str r1, [r0, #GPIOA_AFRL]

    MOV_imm32 r0, RCC_BASE
    ldr r1, [r0, #RCC_APB1ENR1]
    orr r1, r1, #TIM2EN_BIT
    str r1, [r0, #RCC_APB1ENR1]
    nop
    nop

    MOV_imm32 r0, TIM2_BASE
    ldr r1, [r0, #TIMx_CR1]
    bic r1, r1, #TIMx_CR1_CEN
    str r1, [r0, #TIMx_CR1]
    ldr r1, [r0, #TIMx_CCER]
    bic r1, r1, #TIMx_CCER_CC1E
    str r1, [r0, #TIMx_CCER]

    pop {r0-r3, pc}

@======================================================================
@ device6_timer_output_disable: Disables TIM2 outputs and comprehensively resets its state.
@ This function is crucial for stopping any ongoing TIM2 timer activity and
@ returning the timer to a known, default, and inactive configuration. This
@ prevents unintended signals and prepares the timer for a clean reconfiguration.
@ The reset operations include:
@ 1. TIMx_CR1: Disables Counter (CEN), One-Pulse Mode (OPM), Auto-Reload
@    Preload (ARPE). Sets default direction (up-counting by clearing DIR)
@    and default alignment (edge-aligned by clearing CMS).
@ 2. TIMx_CCER: Disables all channel outputs (e.g., CC1E for Channel 1) and
@    resets output polarities by writing 0 to the entire register.
@ 3. TIMx_CCMR1: Resets Channel 1 mode to Frozen (output compare inactive,
@    input capture disabled) by writing 0 to the register.
@ 4. TIMx_CR2, TIMx_SMCR (Slave Mode Control), TIMx_DIER (DMA/Interrupt Enable):
@    Reset to 0, disabling master/slave modes, DMA requests, and interrupts.
@ 5. TIMx_SR (Status Register): Clears all pending interrupt flags by writing 0.
@ 6. TIMx_CNT (Counter), TIMx_PSC (Prescaler), TIMx_ARR (Auto-Reload Register),
@    and TIMx_CCR1 (Capture/Compare Register 1): All reset to 0.
@======================================================================
.global device6_timer_output_disable
.thumb_func
device6_timer_output_disable:
    push {r0-r2, lr}
    MOV_imm32 r0, TIM2_BASE
    ldr r1, [r0, #TIMx_CR1]
    bic r1, r1, #TIMx_CR1_CEN
    bic r1, r1, #TIMx_CR1_OPM
    bic r1, r1, #TIMx_CR1_ARPE
    bic r1, r1, #TIMx_CR1_DIR
    bic r1, r1, #TIMx_CR1_CMS
    str r1, [r0, #TIMx_CR1]
    movs r1, #0
    str r1, [r0, #TIMx_CCER]
    movs r1, #0
    str r1, [r0, #TIMx_CCMR1]
    movs r1, #0
    str r1, [r0, #TIMx_CR2]
    movs r1, #0
    str r1, [r0, #TIMx_SMCR]
    movs r1, #0
    str r1, [r0, #TIMx_DIER]
    movs r1, #0
    str r1, [r0, #TIMx_SR]
    movs r1, #0
    str r1, [r0, #TIMx_CNT]
    str r1, [r0, #TIMx_PSC]
    str r1, [r0, #TIMx_ARR]
    str r1, [r0, #TIMx_CCR1]
    pop {r0-r2, pc}
