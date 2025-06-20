#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

    .syntax unified
    .thumb

@======================================================================
@ PA8_to_high: Sets GPIO Pin PA8 to a HIGH logic level.
@ This function writes to the GPIO Port A Bit Set/Reset Register (BSRR)
@ to set PA8. The value (1 << 8) corresponds to BS8 (Set bit for pin 8),
@ which atomically sets PA8 HIGH without affecting other pins.
@======================================================================
	.global PA8_to_high
	.thumb_func
PA8_to_high:
	push {r7, lr}

    MOV_imm32 r3, GPIOA_BASE
	mov r1, #(1 << 8)
	str r1, [r3, #GPIOx_BSRR]

	pop {r7, pc}

@======================================================================
@ PA8_to_low: Sets GPIO Pin PA8 to a LOW logic level.
@ This function writes to the GPIO Port A Bit Set/Reset Register (BSRR)
@ to reset PA8. The value (1 << 24) corresponds to BR8 (Reset bit for pin 8,
@ which is pin_number + 16), which atomically sets PA8 LOW
@ without affecting other pins.
@======================================================================
	.global PA8_to_low
	.thumb_func
PA8_to_low:
	push {r7, lr}

    MOV_imm32 r3, GPIOA_BASE
	mov r1, #(1 << 24)
	str r1, [r3, #GPIOx_BSRR]

	pop {r7, pc}

@======================================================================
@ PA8_output_init: Initializes GPIO Pin PA8 for output mode.
@ This function performs the following steps:
@ 1. Enables the clock for GPIO Port A via the RCC_AHB2ENR register.
@ 2. Configures Pin PA8 to General Purpose Output mode (binary 01)
@    in the GPIOA_MODER register.
@ 3. Configures PA8 with no pull-up and no pull-down resistors (binary 00)
@    in the GPIOA_OPUPDR register.
@======================================================================
    .global PA8_output_init
    .thumb_func
PA8_output_init:
    push {r0-r3, lr}

    MOV_imm32 r0, RCC_BASE
    ldr r1, [r0, #AHB2ENR]
    orr r1, r1, #GPIOAEN
    str r1, [r0, #AHB2ENR]

    MOV_imm32 r0, GPIOA_BASE
    ldr r1, [r0, #MODER]

    MOV_imm32 r2, (0b11 << (PA8 * 2))
    bic r1, r1, r2

    MOV_imm32 r2, (0b01 << (PA8 * 2))
    orr r1, r1, r2
    str r1, [r0, #MODER]

    ldr r1, [r0, #OPUPDR]
    MOV_imm32 r2, (0b11 << (PA8 * 2))
    bic r1, r1, r2
    str r1, [r0, #OPUPDR]

    pop {r0-r3, pc}
