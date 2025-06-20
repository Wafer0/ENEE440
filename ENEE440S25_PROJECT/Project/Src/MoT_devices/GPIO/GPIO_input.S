#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

    .syntax unified
    .thumb

	.extern device3_input_lowmsg
	.extern device3_input_highmsg


.text

@======================================================================
@ PA8_input_init: Initializes GPIO Pin PA8 for input mode.
@ This function performs the following configuration steps for PA8:
@ 1. Enables the clock for GPIO Port A via the RCC_AHB2ENR register.
@ 2. Sets the mode for PA8 to Input (00) in the GPIOA_MODER register.
@ 3. Configures PA8 with no pull-up and no pull-down resistors (00)
@    in the GPIOA_OPUPDR register, making it a floating input.
@ This prepares PA8 to read its digital state.
@======================================================================
    .global PA8_input_init
    .thumb_func
PA8_input_init:
    push {r7, lr}

    MOV_imm32 r3, RCC_BASE
    ldr r1, [r3, #AHB2ENR]
    orr r1, r1, #GPIOAEN
    str r1, [r3, #AHB2ENR]

    MOV_imm32 r3, GPIOA_BASE
    ldr r1, [r3, #MODER]
    bic r1, r1, #(0b11 << (PA8 * 2))
    str r1, [r3, #MODER]

    ldr r1, [r3, #OPUPDR]
    bic r1, r1, #(0b11 << (PA8 * 2))
    str r1, [r3, #OPUPDR]

    pop {r7, pc}

@======================================================================
@ PA8_read: Reads the digital state of GPIO Pin PA8.
@ It reads the GPIO Port A Input Data Register (GPIOA_IDR).
@ Specifically, it loads the byte containing PA8 (bits 15-8 of IDR if PA8 is pin 8),
@ and then isolates the least significant bit of that byte, which corresponds
@ to the state of PA8.
@ Returns:
@   r0: 0 if PA8 is LOW, 1 if PA8 is HIGH.
@======================================================================
    .global PA8_read
    .thumb_func
PA8_read:
    push {r7, lr}
    MOV_imm32 r1, 0x48000010
    ldrb    r0, [r1, #0]
    ldrb    r0, [r1, #1]
    ands    r0, r0, #1
    pop {r7, pc}

@======================================================================
@ low_n_skip: Handles the "input LOW" state for the GPIO monitoring task.
@ This function is called when the monitored input (PA8) has
@ transitioned to or is confirmed as LOW.
@ Actions:
@ 1. Reschedules the 'monitor_task' for continued monitoring using 'MoT_taskUpdate'.
@ 2. Posts the "Input is LOW" message to the console via 'MoT_msgPost'.
@ 3. Passes execution control to the next MoT task in the system.
@======================================================================
.global low_n_skip
    .thumb_func
low_n_skip:
    MOV_imm32 r0, monitor_task
  	mov     r1, #NULL
    bl      MoT_taskUpdate
    MOV_imm32 r0, device3_input_lowmsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost
    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

@======================================================================
@ high_n_skip: Handles the "input HIGH" state for the GPIO monitoring task.
@ This function is called when the monitored input (PA8) has
@ transitioned to or is confirmed as HIGH.
@ Actions:
@ 1. Reschedules the 'monitor_task' for continued monitoring using 'MoT_taskUpdate'.
@ 2. Posts the "Input is HIGH" message to the console via 'MoT_msgPost'.
@ 3. Passes execution control to the next MoT task in the system.
@======================================================================
.global high_n_skip
    .thumb_func
high_n_skip:
    MOV_imm32 r0, monitor_task
  	mov     r1, #NULL
    bl      MoT_taskUpdate
    MOV_imm32 r0, device3_input_highmsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost
    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

@======================================================================
@ no_change: Handles the "no change" state for the GPIO monitoring task.
@ This function is called when the monitored input (PA8) has
@ not changed its state since the last check.
@ Actions:
@ 1. Reschedules the 'monitor_task' for continued monitoring using 'MoT_taskUpdate'.
@ 2. Passes execution control to the next MoT task in the system without
@    posting any specific change or state message.
@======================================================================
.global no_change
    .thumb_func
no_change:
    MOV_imm32 r0, monitor_task
  	mov     r1, #NULL
    bl      MoT_taskUpdate
    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]
