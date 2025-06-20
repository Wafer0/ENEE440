#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

.syntax unified
.thumb

.text

@======================================================================
@ device6_tim2_input_init_pa0: Initializes TIM2 for general input on PA0 (TIM2_CH1).
@ This function performs the initial setup for using TIM2 Channel 1 with GPIO PA0
@ as an input. Actions include:
@ 1. Resetting TIM2 to a default state by calling 'device6_timer_output_disable'.
@ 2. Enabling clocks for GPIOA and TIM2 peripherals.
@ 3. Configuring GPIO PA0 for Alternate Function 1 (AF1), mapping it to TIM2_CH1.
@ 4. Setting TIM2 Channel 1 (TIMx_CCMR1.CC1S) to input mode, mapped to TI1.
@ 5. Initially disabling the TIM2 Channel 1 capture/compare feature (TIMx_CCER.CC1E).
@ This prepares TIM2 for more specific input configurations such as event counting
@ or input capture, which are handled by other functions.
@======================================================================
.global device6_tim2_input_init_pa0
.thumb_func
device6_tim2_input_init_pa0:
    push {r0-r7, lr}

    bl device6_timer_output_disable

    MOV_imm32 r0, RCC_BASE
    ldr r1, [r0, #RCC_AHB2ENR]
    orr r1, r1, #GPIOAEN_BIT
    str r1, [r0, #RCC_AHB2ENR]

    ldr r1, [r0, #RCC_APB1ENR1]
    orr r1, r1, #TIM2EN_BIT
    str r1, [r0, #RCC_APB1ENR1]
    nop
    nop

    MOV_imm32 r0, GPIOA_BASE
    ldr r1, [r0, #GPIOA_MODER]
    ldr r2, =~(0b11 << PA0_MODER_Pos)
    and r1, r1, r2
    ldr r2, =(0b10 << PA0_MODER_Pos)
    orr r1, r1, r2
    str r1, [r0, #GPIOA_MODER]

    ldr r1, [r0, #GPIOA_AFRL]
    ldr r2, =~(0b1111 << PA0_AFRL_Pos)
    and r1, r1, r2
    ldr r2, =(GPIO_AF1_TIM2 << PA0_AFRL_Pos)
    orr r1, r1, r2
    str r1, [r0, #GPIOA_AFRL]

    MOV_imm32 r0, TIM2_BASE

    ldr r1, [r0, #TIMx_CCMR1]
    bic r1, r1, #TIM_CCMR1_CC1S_Msk
    orr r1, r1, #(0b01 << TIM_CCMR1_CC1S_Pos)
    str r1, [r0, #TIMx_CCMR1]

    ldr r1, [r0, #TIMx_CCER]
    bic r1, r1, #TIM_CCER_CC1E_Msk
    str r1, [r0, #TIMx_CCER]

    pop {r0-r7, pc}
