#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

    .syntax unified
    .thumb
.extern trigger_state
.extern PA8_init
.extern PA8_input_init
.extern PA8_read
.extern PA8_output_init
.extern PA8_to_low
.extern PA8_to_high
.extern arg_retrieve_half
.extern delay
.extern EXTI1_init
.extern MoT_msgPost
.extern MoT_taskUpdate
.extern consoleMsgs

    .text

@======================================================================
@ device3_cmdHandler: Command dispatcher for Device 3 (GPIO).
@ It reads a command ID byte from the MoT message payload (r0),
@ masks it to ensure it's within the valid range (0-10 for this device),
@ and then uses a table branch (TBB) to jump to the appropriate
@ command processing routine listed in the 'device3_cmds' table.
@ r0: Pointer to MoT command payload; first byte is command ID.
@ r1: Used to store and manipulate the command ID.
@======================================================================
    .global device3_cmdHandler
    .thumb_func
device3_cmdHandler:
    push {r7, lr}
    ldrb r1, [r0], #1
    and  r1, r1, #0x0F
    tbb  [pc, r1]

device3_cmds:
    .byte (device3_initialize - device3_cmds)/2
    .byte (device3_set_low - device3_cmds)/2
    .byte (device3_set_high - device3_cmds)/2
    .byte (device3_scheduled_output - device3_cmds)/2
    .byte (device3_repetitive - device3_cmds)/2
    .byte (device3_input_read - device3_cmds)/2
    .byte (device3_scheduled_read - device3_cmds)/2
    .byte (device3_monitored - device3_cmds)/2
    .byte (device3_trig - device3_cmds)/2
    .byte (device3_stop_monitor - device3_cmds)/2
    .byte (device3_trig_result - device3_cmds)/2
    .align 1

    MoT_core_m    device3, device3_cmdHandler, device3_skiptask

    .data

	MoT_varAlloc_m device3_t_off, device3_T_OFF
	MoT_varAlloc_m device3_t_on, device3_T_ON
	MoT_varAlloc_m device3_previous, device3_PREVIOUS

.global device3_input_highmsg
.global device3_input_lowmsg
    MoT_msgLink_m device3_initmsg, device3_inittxt, device3_initmsglen
device3_inittxt:
    .ascii "device3 has been initialized\n\r\0"
    .equ device3_initmsglen, (. - device3_inittxt)

    MoT_msgLink_m device3_input_lowmsg, device3_input_lowtxt, device3_input_lowmsglen
device3_input_lowtxt:
    .ascii "Input is LOW\n\r\0"
    .equ device3_input_lowmsglen, (. - device3_input_lowtxt)

    MoT_msgLink_m device3_input_highmsg, device3_input_hightxt, device3_input_highmsglen
device3_input_hightxt:
    .ascii "Input is HIGH\n\r\0"
    .equ device3_input_highmsglen, (. - device3_input_hightxt)

    MoT_msgLink_m device3_output_lowmsg, device3_output_lowtxt, device3_output_lowmsglen
device3_output_lowtxt:
    .ascii "Output is LOW\n\r\0"
    .equ device3_output_lowmsglen, (. - device3_output_lowtxt)

    MoT_msgLink_m device3_output_highmsg, device3_output_hightxt, device3_output_highmsglen
device3_output_hightxt:
    .ascii "Output is HIGH\n\r\0"
    .equ device3_output_highmsglen, (. - device3_output_hightxt)

    MoT_msgLink_m device3_waitingmsg, device3_waitingtxt, device3_waitingmsglen
device3_waitingtxt:
    .ascii "Waiting on PA8\n\r\0"
    .equ device3_waitingmsglen, (. - device3_waitingtxt)

    MoT_msgLink_m device3_monitormsg, device3_monitortxt, device3_monitormsglen
device3_monitortxt:
    .ascii "Monitor on PA8\n\r\0"
    .equ device3_monitormsglen, (. - device3_monitortxt)

    MoT_msgLink_m device3_trigmsg, device3_trigtxt, device3_trigmsglen
device3_trigtxt:
    .ascii "Trigger on PA1\n\r\0"
    .equ device3_trigmsglen, (. - device3_trigtxt)

    MoT_msgLink_m device3_change_detectedmsg, device3_change_detectedtxt, device3_change_detectedmsglen
device3_change_detectedtxt:
    .ascii "Change on PA8\n\r\0"
    .equ device3_change_detectedmsglen, (. - device3_change_detectedtxt)

    MoT_msgLink_m device3_stop_monitor_return_resutlsmsg, device3_stop_monitor_return_resutlstxt, device3_stop_monitor_return_resutlsmsglen
device3_stop_monitor_return_resutlstxt:
    .ascii "Monitor Has Stopped\n\r\0"
    .equ device3_stop_monitor_return_resutlsmsglen, (. - device3_stop_monitor_return_resutlstxt)

    MoT_msgLink_m device3_trig_resultmsg, device3_trig_resulttxt, device3_trig_resultmsglen
device3_trig_resulttxt:
    .ascii "Result from Trigger\n\r\0"
    .equ device3_trig_resultmsglen, (. - device3_trig_resulttxt)

    MoT_msgLink_m device3_repetitive_onmsg, device3_repetitive_ontxt, device3_repetitive_onmsglen
device3_repetitive_ontxt:
    .ascii "device3 repetitive mode is on\n\r\0"
    .equ device3_repetitive_onmsglen, (. - device3_repetitive_ontxt)

    MoT_msgLink_m device3_schedule_onmsg, device3_schedule_ontxt, device3_schedule_onmsglen
device3_schedule_ontxt:
    .ascii "device3 scheduled a task on\n\r\0"
    .equ device3_schedule_onmsglen, (. - device3_schedule_ontxt)

.text

@======================================================================
@ device3_initialize: Initializes Device 3 (GPIO). (Command 0x00)
@ Calls 'PA8_init' to set up GPIO pin PA8. After initialization,
@ it posts the message "device3 has been initialized" to the console.
@======================================================================
	.global device3_initialize
	.thumb_func
device3_initialize:
    bl PA8_init
    add r0, rDEVP, #device3_initmsg_OFFSET
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost
    pop {r7, pc}

@======================================================================
@ device3_input_read: Reads the immediate digital state of GPIO pin PA8. (Command 0x05)
@ First, it calls 'PA8_input_init' to ensure PA8 is configured as an input. Then, it calls 'PA8_read'
@ to get the current logic level of PA8 (result in r0: 0 for LOW, non-0 for HIGH).
@ Finally, it posts "Input is HIGH" or "Input is LOW" to the console accordingly.
@======================================================================
	.global device3_input_read
	.thumb_func
device3_input_read:
	bl PA8_input_init
	bl PA8_read
	cmp r0, #0
	beq low
	b high

@======================================================================
@ device3_scheduled_read: Reads the digital state of PA8 after a specified delay. (Command 0x06)
@ Ensures PA8 is configured for input by calling 'PA8_input_init'.
@ Posts "Waiting on PA8" to the console.
@ Retrieves a 16-bit delay value from the command payload using 'arg_retrieve_half'.
@ Executes the delay using the 'delay' function.
@ After the delay, reads PA8 using 'PA8_read' and posts its state ("Input is HIGH" or "Input is LOW").
@ r0: Pointer to command payload containing the 16-bit delay.
@======================================================================
    .global device3_scheduled_read
    .thumb_func
device3_scheduled_read:
	bl PA8_input_init
    mov r5, r0
    MOV_imm32 r0, device3_waitingmsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost
    mov r0, r5
    bl PA8_input_init
    bl arg_retrieve_half
    mov r5, r0
    mov r0, r1
    bl delay
    mov r0, r5
    bl PA8_read
    cmp r0, #0
    beq low
high:
    MOV_imm32 r0, device3_input_highmsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost
    b done
low:
    MOV_imm32 r0, device3_input_lowmsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost
done:
    pop {r7, pc}

@======================================================================
@ device3_monitored: Initiates continuous monitoring of GPIO pin PA8. (Command 0x07)
@ Posts "Monitor on PA8" to the console.
@ Configures PA8 for input using 'PA8_input_init'.
@ Reads the initial state of PA8 using 'PA8_read' and stores it in the
@ device-specific variable 'device3_PREVIOUS'.
@ Schedules the 'monitor_task' using 'MoT_taskUpdate' to periodically check PA8.
@======================================================================
    .global device3_monitored
    .thumb_func
device3_monitored:
	MOV_imm32 r0, device3_monitormsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost
	bl PA8_input_init
	bl PA8_read
    str r1, [rDEVP, #device3_PREVIOUS]
    mov     r1, #NULL
  	MOV_imm32 r0, monitor_task
    bl      MoT_taskUpdate
    pop {r7, pc}

@======================================================================
@ device3_trig: Configures an external interrupt on PA1 to trigger actions related to PA8. (Command 0x08)
@ Initializes PA8 for input using 'PA8_input_init' so its state can be captured.
@ Sets a global 'trigger_state' variable to 8, associating this EXTI1 configuration
@ with Device 3's PA8 input capture functionality.
@ Calls 'EXTI1_init' to set up PA1 as an EXTI line.
@ Posts "Trigger on PA1" to the console.
@======================================================================
    .global device3_trig
    .thumb_func
device3_trig:
	bl PA8_input_init
  	ldr r0, =trigger_state
	mov r1, #8
	str r1, [r0]
	bl    EXTI1_init
    MOV_imm32 r0, device3_trigmsg
    MOV_imm32 r1, consoleMsgs
    bl      MoT_msgPost
    pop {r7, pc}

@======================================================================
@ device3_trig_result: Reports that a trigger event has occurred. (Command 0x0A)
@ This command is used by the host PC to confirm
@ that trigger events (set up by Command 0x08) have been processed.
@ The actual capture and reporting of PA8's state upon a trigger is handled
@ asynchronously by the 'EXTI1_IRQHandler'. This function simply posts
@ the message "Result from Trigger" to the console.
@======================================================================
    .global device3_trig_result
    .thumb_func
device3_trig_result:
    MOV_imm32 r0, device3_trig_resultmsg
    MOV_imm32 r1, consoleMsgs
    bl      MoT_msgPost
    pop {r7, pc}

@======================================================================
@ device3_stop_monitor: Stops the continuous monitoring of GPIO pin PA8. (Command 0x09)
@ It replaces the active 'monitor_task' for Device 3 with 'device3_skiptask'
@ using 'MoT_taskUpdate', effectively halting further periodic checks of PA8.
@ After stopping the monitoring, it posts the message "Monitor Has Stopped"
@ to the console. Any state changes detected by 'monitor_task' just before
@ stopping would have been reported by 'monitor_task' itself.
@======================================================================
.global device3_stop_monitor
.thumb_func
device3_stop_monitor:
    MOV_imm32 r0, device3_skiptask
    mov r1, #NULL
    bl MoT_taskUpdate
    mov r0, #0
    MOV_imm32 r0, device3_stop_monitor_return_resutlsmsg
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    mov r0, #0
    pop {r7, pc}

@======================================================================
@ device3_set_low: Immediately sets the output of GPIO pin PA8 to LOW. (Command 0x01)
@ Calls 'PA8_output_init' to ensure PA8 is configured for output mode.
@ Then calls 'PA8_to_low' to drive the PA8 pin to a logic LOW state.
@ Posts "Input is LOW" to the console as confirmation
@======================================================================
	.global device3_set_low
	.thumb_func
device3_set_low:
	bl PA8_output_init
    bl PA8_to_low
	MOV_imm32 r0, device3_output_lowmsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost
    pop {r7, pc}

@======================================================================
@ device3_set_high: Immediately sets the output of GPIO pin PA8 to HIGH. (Command 0x02)
@ Calls 'PA8_output_init' to ensure PA8 is configured for output mode.
@ Then calls 'PA8_to_high' to drive the PA8 pin to a logic HIGH state.
@ Posts "Input is HIGH" to the console as confirmation
@======================================================================
	.global device3_set_high
	.thumb_func
device3_set_high:
	bl PA8_output_init
    bl PA8_to_high
	MOV_imm32 r0, device3_output_highmsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost
    pop {r7, pc}

@======================================================================
@ device3_scheduled_output: Sets PA8 output to a specified level after a delay. (Command 0x03)
@ Configures PA8 for output using 'PA8_output_init'.
@ Posts "device3 scheduled a task on" to the console.
@ Retrieves a 16-bit delay and a 16-bit state (0 for LOW, non-0 for HIGH)
@ from the command payload. After the delay, drives PA8 to the requested state.
@ r0: Pointer to command payload containing 16-bit delay then 16-bit state.
@======================================================================
	.global device3_scheduled_output
	.thumb_func
device3_scheduled_output:
	bl PA8_output_init
	mov r5, r0
	MOV_imm32 r0, device3_schedule_onmsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost
    mov r0, r5
	bl arg_retrieve_half
	mov r5, r0
	mov r0, r1
    bl delay
    mov r0, r5
	ldrh r1, [r0], #2
	cbz r1, off
on:
    bl PA8_to_high
	pop {r7, pc}
off:
	bl PA8_to_low
    pop {r7, pc}

@======================================================================
@ device3_repetitive: Generates a repetitive square wave on PA8. (Command 0x04)
@ Posts "device3 repetitive mode is on" to the console.
@ Configures PA8 for output using 'PA8_output_init'.
@ Retrieves parameters from payload: 16-bit cycle count, 16-bit T_OFF (duration PA8 is LOW),
@ and 16-bit T_ON (duration PA8 is HIGH). Stores T_OFF and T_ON in device variables.
@ Loops for the specified number of cycles: delays for T_OFF, sets PA8 HIGH,
@ delays for T_ON, sets PA8 LOW.
@ r0: Pointer to command payload.
@======================================================================
	.global device3_repetitive
	.thumb_func
device3_repetitive:
	mov r7, r0
	MOV_imm32 r0, device3_repetitive_onmsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost
    mov r0, r7
	bl PA8_output_init
	mov r7, r6
    bl arg_retrieve_half
    mov r6, r1
	bl arg_retrieve_half
	str r1, [rDEVP, #device3_T_OFF]
	bl arg_retrieve_half
	str r1, [rDEVP, #device3_T_ON]
loop:
	ldrh r1, [rDEVP, device3_T_OFF]
	mov r7, r0
    mov r0, r1
    bl delay
    bl PA8_to_high
    mov r0, r7
	ldrh r1, [rDEVP, device3_T_ON]
	mov r7, r0
    mov r0, r1
    bl delay
    bl PA8_to_low
    mov r0, r7
	sub r6, r6, #1
	cmp r6, #0
	bne loop
	pop {r7, pc}

@======================================================================
@ monitor_task: Periodic MoT task to check PA8 state and report changes.
@ This task is scheduled by 'device3_monitored' (Cmd 0x07).
@ On each invocation by the MoT scheduler:
@ 1. Introduces a short delay (100 units).
@ 2. Initializes PA8 for input ('PA8_input_init').
@ 3. Reads the current state of PA8 ('PA8_read').
@ 4. Compares the current state with the previously stored state ('device3_PREVIOUS').
@ 5. If a change is detected:
@    a. Posts "Change on PA8" to the console.
@    b. Posts the new state ("Input is HIGH" or "Input is LOW").
@    c. Updates 'device3_PREVIOUS' with the new state.
@ 6. Passes control to the next MoT task in the system.
@ It continues to be called by the MoT scheduler as long as it's the active
@ task for Device 3.
@======================================================================
	.global monitor_task
    .thumb_func
monitor_task:
	mov r0, #100
	bl delay
    bl  PA8_input_init
    bl  PA8_read
    mov r2, r0
    ldr r1, [rDEVP, #device3_PREVIOUS]
    str r2, [rDEVP, #device3_PREVIOUS]
    cmp r1, r2
    beq no_change
    ldr r0, =device3_change_detectedmsg
    ldr r1, =consoleMsgs
    bl  MoT_msgPost
    ldr r0, [rDEVP, #device3_PREVIOUS]
    cmp r0, #0
    bne high_n_skip
    b low_n_skip
no_change:
    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]
high_n_skip:
    ldr r0, =device3_input_highmsg
    ldr r1, =consoleMsgs
    bl  MoT_msgPost
    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]
low_n_skip:
    ldr r0, =device3_input_lowmsg
    ldr r1, =consoleMsgs
    bl  MoT_msgPost
    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

@======================================================================
@ device3_skiptask: A minimal MoT task for Device 3 that does nothing.
@ Its purpose is to act as a placeholder or default task. When executed,
@ it immediately passes control to the next scheduled MoT task in the system
@ by loading the next task's context (rDEVP) and jumping to its execution address.
@ This is used, for example, to stop the 'monitor_task'.
@======================================================================
.global device3_skiptask
.thumb_func
device3_skiptask:
    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]
