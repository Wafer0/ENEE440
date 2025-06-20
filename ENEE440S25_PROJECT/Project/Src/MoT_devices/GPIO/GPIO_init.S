#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

    .syntax unified
    .thumb
.text

@======================================================================
@ PA8_init: Initializes GPIO Pin PA8 for general-purpose output.
@ This function performs the following steps:
@ 1. Enables the clock for GPIO Port A via the RCC_AHB2ENR register.
@ 2. Configures Pin PA8 to General Purpose Output mode (01) in GPIOA_MODER.
@ 3. Sets the output type for PA8 to Push-Pull (0) in GPIOA_OTYPER.
@ 4. Configures PA8 with no pull-up and no pull-down resistors (00)
@    in GPIOA_OPUPDR.
@ This setup prepares PA8 to be driven HIGH or LOW by the microcontroller.
@======================================================================
    .global PA8_init
    .thumb_func
PA8_init:
    push {r7, lr}

    MOV_imm32 r3, RCC_BASE
    ldr r1, [r3, #AHB2ENR]
    orr r1, r1, #GPIOAEN
    str r1, [r3, #AHB2ENR]

    MOV_imm32 r3, GPIOA_BASE
    ldr r1, [r3, #MODER]

    bic r1, r1, #(0b11 << (PA8 * 2))

    orr r1, r1, #(0b01 << (PA8 * 2))
    str r1, [r3, #MODER]

    ldr r1, [r3, #OTYPER]

    bic r1, r1, #(1 << PA8)
    str r1, [r3, #OTYPER]

    ldr r1, [r3, #OPUPDR]

    bic r1, r1, #(0b11 << (PA8 * 2))
    str r1, [r3, #OPUPDR]

    pop {r7, pc}
