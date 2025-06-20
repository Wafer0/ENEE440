#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

.syntax unified
.thumb

.extern trigger_state

.data
.global pwm_arr_val
pwm_arr_val: .word 1999999
.global pwm_arr_duty
pwm_arr_duty: .word 50
.global opm_delay_ticks_val
opm_delay_ticks_val: .word 1999999
.global opm_width_ticks_val
opm_width_ticks_val: .word 1999999
.global pfm_fixed_pulse_width_ticks_val
pfm_fixed_pulse_width_ticks_val: .word 1000
.global pfm_current_arr_val
pfm_current_arr_val: .word 9999
.global single_freq_cycle_target_hz_val
single_freq_cycle_target_hz_val: .word 2
.global simple_pulse_width_ticks_val
simple_pulse_width_ticks_val: .word 250000
.text

@======================================================================
@ device6_cmdHandler: Command dispatcher for Device 6 (Timer).
@ Reads a command ID byte from the MoT message payload (r0), masks it to
@ ensure it's within the valid range (0-13 for currently defined commands),
@ and then uses a table branch (TBB) to jump to the appropriate command
@ processing routine listed in the 'device6_cmds' table.
@ r0: Pointer to MoT command payload; first byte is command ID.
@ r1: Used to store and manipulate the command ID.
@======================================================================
    .global device6_cmdHandler
    .thumb_func
device6_cmdHandler:
    push {r7, lr}
    ldrb r1, [r0], #1
    and  r1, r1, #0x0f
    tbb  [pc, r1]

device6_cmds:
    .byte (device6_initialize - device6_cmds)/2
    .byte (device6_pwm_on - device6_cmds)/2
    .byte (device6_pfm_on - device6_cmds)/2
    .byte (device6_pulse_on - device6_cmds)/2
    .byte (device6_pulse_width_on - device6_cmds)/2
    .byte (device6_pulse_frequency_on - device6_cmds)/2
    .byte (device6_triggered_init - device6_cmds)/2
    .byte (device6_triggered - device6_cmds)/2
    .byte (device6_off - device6_cmds)/2
    .byte (device6_skiptask - device6_cmds)/2
    .byte (device6_skiptask - device6_cmds)/2
    .byte (device6_skiptask - device6_cmds)/2
    .byte (device6_skiptask - device6_cmds)/2
    .byte (device6_init_in - device6_cmds)/2
    .align 1

    MoT_core_m    device6, device6_cmdHandler, device6_skiptask

.data

MoT_msgLink_m device6_initmsg,  device6_inittxt,  device6_initmsglen
device6_inittxt:
    .ascii "device6 is Initialized\n\r\0"
.equ device6_initmsglen, (. - device6_inittxt)

MoT_msgLink_m device6_pwm_onmsg,  device6_pwm_ontxt,  device6_pwm_onmsglen
device6_pwm_ontxt:
    .ascii "device6 PWM ON\n\r\0"
.equ device6_pwm_onmsglen, (. - device6_pwm_ontxt)

MoT_msgLink_m device6_pfm_onmsg,  device6_pfm_ontxt,  device6_pfm_onmsglen
device6_pfm_ontxt:
    .ascii "device6 PFM ON\n\r\0"
.equ device6_pfm_onmsglen, (. - device6_pfm_ontxt)

MoT_msgLink_m device6_pulse_onmsg,  device6_pulse_ontxt,  device6_pulse_onmsglen
device6_pulse_ontxt:
    .ascii "device6 Pulse ON\n\r\0"
.equ device6_pulse_onmsglen, (. - device6_pulse_ontxt)

MoT_msgLink_m device6_pulse_frequency_onmsg,  device6_pulse_frequency_ontxt,  device6_pulse_frequency_onmsglen
device6_pulse_frequency_ontxt:
    .ascii "device6 Pulse Frequency ON\n\r\0"
.equ device6_pulse_frequency_onmsglen, (. - device6_pulse_frequency_ontxt)

MoT_msgLink_m device6_pulse_width_onmsg,  device6_pulse_width_ontxt,  device6_pulse_width_onmsglen
device6_pulse_width_ontxt:
    .ascii "device6 Pulse Width ON\n\r\0"
.equ device6_pulse_width_onmsglen, (. - device6_pulse_width_ontxt)

MoT_msgLink_m device6_trig_onmsg,  device6_trig_ontxt,  device6_trig_onmsglen
device6_trig_ontxt:
    .ascii "device6 Trigger Enabled\n\r\0"
.equ device6_trig_onmsglen, (. - device6_trig_ontxt)

MoT_msgLink_m device6_trig_armedmsg,  device6_trig_armedtxt,  device6_trig_armedmsglen
device6_trig_armedtxt:
    .ascii "device6 Trigger Armed With Given Command\n\r\0"
.equ device6_trig_armedmsglen, (. - device6_trig_armedtxt)

MoT_msgLink_m device6_fun_offmsg,  device6_fun_offtxt,  device6_fun_offmsglen
device6_fun_offtxt:
    .ascii "device6 Fucntion OFF\n\r\0"
.equ device6_fun_offmsglen, (. - device6_fun_offtxt)
.align 1

MoT_msgLink_m device6_input_resultmsg,  device6_input_resulttxt,  device6_input_resultmsglen
device6_input_resulttxt:
    .ascii "Input Function Result 0x00000000\n\r\0"
.equ device6_input_resultmsglen, (. - device6_input_resulttxt)
.align 1

.text
@======================================================================
@ device6_skiptask: A minimal MoT task for Device 6.
@ This task performs no specific action for Device 6. It immediately
@ passes execution control to the next scheduled MoT task in the system.
@ It's used as the default task or to explicitly stop other device-specific
@ periodic timer operations if they were managed as MoT tasks.
@======================================================================
.global device6_skiptask
.thumb_func
device6_skiptask:
    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

@======================================================================
@ device6_init_in: Initializes TIM2 for an input operation (Command 0x0D)
@ 1. Calls 'device6_timer_output_disable' to reset TIM2 state.
@ 2. Calls 'device6_tim2_input_init_pa0' to configure TIM2
@    to receive input from PA0.
@ 3. Branches to 'post_msg_and_return' to post the "device6 is Initialized" message.
@ This sets up TIM2 to start counting external events on PA0.
@======================================================================
.global device6_init_in
.thumb_func
device6_init_in:
	bl device6_timer_output_disable
	bl device6_tim2_input_init_pa0
    add r0, rDEVP, #device6_initmsg_OFFSET
	b post_msg_and_return
    pop {r7, pc}

@======================================================================
@ device6_initialize: Initializes Device 6 (Timer). (Command 0x00)
@ This function performs the basic setup for the TIM2 peripheral for output operations.
@ 1. Calls 'device6_timer_output_disable' to ensure any previous timer
@    activity is stopped and timer outputs are disabled.
@ 2. Calls 'device6_timer_base_init' to perform fundamental timer configurations
@    such as enabling the TIM2 clock and setting up the GPIO pin (e.g., PA5)
@    for alternate function output (TIM2_CH1).
@ 3. Branches to 'post_msg_and_return' to post the "device6 is Initialized" message.
@======================================================================
.global device6_initialize
.thumb_func
device6_initialize:
	bl device6_timer_output_disable
    bl device6_timer_base_init
    add r0, rDEVP, #device6_initmsg_OFFSET
	b post_msg_and_return

@======================================================================
@ device6_pwm_on: Enables PWM output on TIM2_CH1 (PA5). (Command 0x01)
@ Configures and starts Timer 2 to generate a PWM signal.
@ 1. Disables current timer output.
@ 2. Retrieves a 32-bit ARR value (period) from the command payload using
@    'arg_retrieve' and stores it in the global 'pwm_arr_val'.
@ 3. Retrieves a 16-bit duty cycle percentage from the command payload using
@    'arg_retrieve_half' and stores it in the global 'pwm_arr_duty'.
@ 4. Calls 'device6_pwm_enable' to apply these parameters and start PWM.
@ 5. Branches to 'post_msg_and_return' to post "device6 PWM ON" message.
@ r0: Input, pointer to command payload.
@======================================================================
.global device6_pwm_on
.thumb_func
device6_pwm_on:
	bl device6_timer_output_disable
	bl arg_retrieve
    ldr r6, =pwm_arr_val
	str r1, [r6]
	bl arg_retrieve_half
	ldr r6, =pwm_arr_duty
	str r1, [r6]
    bl device6_pwm_enable
    add r0, rDEVP, #device6_pwm_onmsg_OFFSET
	b post_msg_and_return

@======================================================================
@ device6_pulse_on: Enables a simple single pulse on TIM2_CH1 (PA5). (Command 0x03)
@ Generates a single pulse of a specified width.
@ 1. Disables current timer output.
@ 2. Retrieves a 32-bit pulse width (in timer ticks) from the command payload
@    using 'arg_retrieve' and stores it in 'simple_pulse_width_ticks_val'.
@ 3. Calls 'device6_simple_pulse_enable' to configure and start the one-pulse output.
@ 4. Branches to 'post_msg_and_return' to post "device6 Pulse ON" message.
@ r0: Input, pointer to command payload.
@======================================================================
.global device6_pulse_on
.thumb_func
device6_pulse_on:
	bl device6_timer_output_disable
	bl arg_retrieve
    ldr r6, =simple_pulse_width_ticks_val
	str r1, [r6]
    bl device6_simple_pulse_enable
	add r0, rDEVP, #device6_pulse_onmsg_OFFSET
	b post_msg_and_return

@======================================================================
@ device6_pulse_width_on: Enables One-Pulse Mode (OPM) with specified delay and width. (Command 0x04)
@ Generates a single pulse on TIM2_CH1 (PA5) after an initial delay.
@ 1. Disables current timer output.
@ 2. Retrieves a 32-bit delay (in ticks) from payload using 'arg_retrieve'
@    and stores it in 'opm_delay_ticks_val'.
@ 3. Retrieves a 32-bit pulse width (in ticks) from payload using 'arg_retrieve'
@    and stores it in 'opm_width_ticks_val'.
@ 4. Calls 'device6_opm_enable' to apply parameters and start the OPM pulse.
@ 5. Branches to 'post_msg_and_return' to post "device6 Pulse Width ON" message.
@ r0: Input, pointer to command payload.
@======================================================================
.global device6_pulse_width_on
.thumb_func
device6_pulse_width_on:
	bl device6_timer_output_disable
	bl arg_retrieve
    ldr r6, =opm_delay_ticks_val
	str r1, [r6]
	bl arg_retrieve
    ldr r6, =opm_width_ticks_val
	str r1, [r6]
    bl device6_opm_enable
	add r0, rDEVP, #device6_pulse_width_onmsg_OFFSET
	b post_msg_and_return

@======================================================================
@ device6_pulse_frequency_on: Generates a single cycle of a square wave. (Command 0x05)
@ Produces one pulse (50% duty cycle) at a specified target frequency on TIM2_CH1 (PA5).
@ 1. Disables current timer output.
@ 2. Retrieves a 32-bit target frequency (in Hz) from payload using 'arg_retrieve'
@    and stores it in 'single_freq_cycle_target_hz_val'.
@ 3. Calls 'device6_single_freq_cycle_enable' to configure and start the single cycle output.
@ 4. Branches to 'post_msg_and_return' to post "device6 Pulse Frequency ON" message.
@ r0: Input, pointer to command payload.
@======================================================================
.global device6_pulse_frequency_on
.thumb_func
device6_pulse_frequency_on:
	bl device6_timer_output_disable
	bl arg_retrieve
    ldr r6, =single_freq_cycle_target_hz_val
	str r1, [r6]
    bl device6_single_freq_cycle_enable
	add r0, rDEVP, #device6_pulse_frequency_onmsg_OFFSET
	b post_msg_and_return

@======================================================================
@ device6_triggered_init: Initializes the external trigger (EXTI1 on PA1) for Device 6. (Command 0x06)
@ Prepares TIM2 to respond to an external trigger event.
@ 1. Sets the global 'trigger_state' variable to 0 (or a default indicating TIM2 context
@    for EXTI, to be further specified by the arming command).
@ 2. Calls 'EXTI1_init' to configure PA1 as an external interrupt input.
@ 3. Posts "device6 Trigger Enabled" message to the console.
@======================================================================
.global device6_triggered_init
.thumb_func
device6_triggered_init:
	ldr r4, =trigger_state
	mov r1, #0
	str r1, [r4]
	bl EXTI1_init
	MOV_imm32 r0, device6_trig_onmsg
    MOV_imm32 r1, consoleMsgs
    bl  MoT_msgPost
    pop {r7, pc}

@======================================================================
@ device6_off: Turns off the currently active TIM2 timer function. (Command 0x08)
@ Calls 'device6_timer_output_disable' to stop any ongoing PWM, PFM, or pulse
@ generation and disable timer outputs.
@ Then, branches to 'post_msg_and_return' to post "device6 Fucntion OFF" message.
@======================================================================
.global device6_off
.thumb_func
device6_off:
    bl device6_timer_output_disable
    add r0, rDEVP, #device6_fun_offmsg_OFFSET
	b post_msg_and_return

@======================================================================
@ device6_triggered: Arms a specific TIM2 function for external trigger. (Command 0x07)
@ Configures which timer operation (PWM, PFM, Pulse, etc.) will be executed
@ when an external trigger event occurs on PA1.
@ 1. Calls 'prep_trig' which reads the sub-command and its parameters from the
@    command payload (r0). 'prep_trig' stores these parameters in temporary
@    global variables and sets the 'trigger_state' (e.g., 3-7) to indicate the
@    specific armed function.
@ 2. Posts "device6 Trigger Armed With Given Command" message to the console.
@ r0: Input, pointer to command payload containing sub-command and parameters.
@======================================================================
.global device6_triggered
.thumb_func
device6_triggered:
	bl prep_trig
	MOV_imm32 r0, #device6_trig_armedmsg
	MOV_imm32 r1, consoleMsgs
    bl  MoT_msgPost
    pop {r7, pc}

@======================================================================
@ device6_pfm_on: Enables Pulse Frequency Modulation (PFM) on TIM2_CH1 (PA5). (Command 0x02)
@ Generates a continuous square wave with a 50% duty cycle at a target frequency.
@ 1. Disables current timer output.
@ 2. Retrieves the 32-bit target frequency (in Hz) from payload using 'arg_retrieve'.
@ 3. Calls 'freq_to_arr_ticks' to convert this target frequency into an equivalent
@    ARR value (period in timer ticks) for the PWM hardware.
@ 4. Stores this calculated ARR in 'pwm_arr_val'.
@ 5. Sets 'pwm_arr_duty' to 50 (for 50% duty cycle).
@ 6. Calls 'device6_pwm_enable' to configure and start TIM2 in PWM mode, effectively
@    generating the PFM signal.
@ 7. Branches to 'post_msg_and_return' to post "device6 PFM ON" message.
@ r0: Input, pointer to command payload.
@======================================================================
.global device6_pfm_on
.thumb_func
device6_pfm_on:
	bl device6_timer_output_disable
	bl arg_retrieve
	mov r0, r1
	bl freq_to_arr_ticks
	ldr r6, =pwm_arr_val
	str r0, [r6]
	mov r0, #50
	ldr r6, =pwm_arr_duty
	str r0, [r6]
    bl device6_pwm_enable
	add r0, rDEVP, #device6_pfm_onmsg_OFFSET
	b post_msg_and_return

@======================================================================
@ device6_post_input_result: Formats and posts a 32-bit result from a timer input function.
@ This helper function takes a 32-bit value (e.g., event count, period, pulse width)
@ in register r0. It converts this value into an 8-character hexadecimal string
@ and inserts it into the predefined message "Input Function Result 0x00000000".
@ The formatted message is then posted to the console.
@ r0: Input, the 32-bit value to be formatted and posted.
@======================================================================
.global device6_post_input_result
.thumb_func
device6_post_input_result:
    push {r1-r7, lr}
    mov r4, r0

    MOV_imm32 r1, device6_input_resultmsg
    add r2, r1, #24

    mov r7, #8
convert_hex_to_buffer_loop_new:
    mov r5, r4
    lsr r5, r5, #28
    and r5, r5, #0xF

    bl nibble_to_ascii
    strb r0, [r2], #1

    lsl r4, r4, #4
    subs r7, r7, #1
    bne convert_hex_to_buffer_loop_new

	MOV_imm32 r0, #device6_input_resultmsg
	MOV_imm32 r1, consoleMsgs
    bl  MoT_msgPost

    pop {r1-r7, pc}
