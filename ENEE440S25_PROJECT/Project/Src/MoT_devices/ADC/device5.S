#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

    .syntax unified
    .thumb

.extern trigger_state

    .text

@======================================================================
@ device5_cmdHandler: Handles incoming commands for Device 5 (ADC).
@ It reads a command ID from the MoT message, masks it to ensure it's
@ within the valid range, and then uses a table branch (TBB) to jump
@ to the appropriate command processing routine based on the device5_cmds table.
@ r0: Pointer to the MoT command payload, command ID is the first byte.
@======================================================================
    .global device5_cmdHandler
    .thumb_func
device5_cmdHandler:
    push {r7, lr}
    ldrb r1, [r0], #1
    and  r1, r1, #0x0F
    tbb  [pc, r1]

device5_cmds:
    .byte (device5_initialize - device5_cmds)/2
    .byte (report_ADC_amp      - device5_cmds)/2
    .byte (device5_checklimits - device5_cmds)/2
	.byte (device5_stop_monitor - device5_cmds)/2
	.byte (device5_trig - device5_cmds)/2
    .align 1

    MoT_core_m    device5, device5_cmdHandler, device5_skiptask
    MoT_varAlloc_m device5_cyclecount, device5_BELOW
    MoT_varAlloc_m device5_reload,     device5_ABOVE

    .data

    MoT_msgLink_m device5_initmsg, device5_inittxt, device5_initmsglen
device5_inittxt:
    .ascii "device5 has been initialized\n\r\0"
    .equ device5_initmsglen, (. - device5_inittxt)

    MoT_msgLink_m device5_stop_monitor_return_resutlsmsg, device5_stop_monitor_return_resutlstxt, device5_stop_monitor_return_resutlsmsglen
device5_stop_monitor_return_resutlstxt:
    .ascii "Monitor Has Stopped\n\r\0"
    .equ device5_stop_monitor_return_resutlsmsglen, (. - device5_stop_monitor_return_resutlstxt)

    MoT_msgLink_m reportADC_reportmsg, reportADC_reporttxt, reportADC_reportmsglen
reportADC_reporttxt:
    .ascii "ADC amplitude read\n\r\0"
    .equ reportADC_reportmsglen, (. - reportADC_reporttxt)

    MoT_msgLink_m device5_voltage_reportmsg, device5_voltage_reporttxt, device5_voltage_reportmsglen
device5_voltage_reporttxt:
    .ascii "Output Vx from ADC              0xNNN\n\r\0"
    .equ device5_voltage_reportmsglen, (. - device5_voltage_reporttxt)

    MoT_msgLink_m device5_monitormsg, device5_monitortxt, device5_monitormsglen
device5_monitortxt:
    .ascii "ADC Range Monitor is On\n\r\0"
    .equ device5_monitormsglen, (. - device5_monitortxt)

    MoT_msgLink_m device5_abovemsg, device5_abovetxt, device5_abovemsglen
device5_abovetxt:
    .ascii "ABOVE LIMIT\n\r\0"
    .equ device5_abovemsglen, (. - device5_abovetxt)

    MoT_msgLink_m device5_belowmsg, device5_belowtxt, device5_belowmsglen
device5_belowtxt:
    .ascii "BELOW LIMIT\n\r\0"
    .equ device5_belowmsglen, (. - device5_belowtxt)

MoT_msgLink_m device5_trigmsg,  device5_trigtxt,   device5_trigmsglen
device5_trigtxt:
    .ascii "device5 Trigger Enabled on PA1\n\r\0"
.equ device5_trigmsglen, (. - device5_trigtxt)

@======================================================================
@ device5_initialize: Initializes the ADC peripheral (Device 5).
@ This function calls ADC_init to perform hardware setup for ADC1 and PA0.
@ After successful initialization, it posts a confirmation message
@ "device5 has been initialized" to the console. Corresponds to command 0x00.
@======================================================================
    .text
    .thumb_func
device5_initialize:
    bl  ADC_init
    add r0, rDEVP, #device5_initmsg_OFFSET
    MOV_imm32 r1, consoleMsgs
    bl  MoT_msgPost
    pop {r7, pc}

@======================================================================
@ device5_trig: Configures an external interrupt on PA1 for Device 5 (ADC).
@ It sets a global 'trigger_state' variable to 2, indicating that
@ Device 5 will handle the EXTI1 interrupt. It then calls EXTI1_init
@ to configure PA1 for a rising edge interrupt. Finally, it posts
@ "device5 Trigger Enabled on PA1" to the console. Corresponds to command 0x04.
@======================================================================
    .global device5_trig
    .thumb_func
device5_trig:
	ldr r0, =trigger_state
	mov r1, #2
	str r1, [r0]
    bl    EXTI1_init
    add   r0, rDEVP, #device5_trigmsg_OFFSET
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}
@======================================================================
@ ADC_init: Initializes the ADC1 peripheral and its associated GPIO pin PA0.
@ Actions include:
@ 1. Initializing PA0 for analog input (calls initPA0).
@ 2. Enabling the ADC12 clock in RCC_AHB2ENR.
@ 3. Selecting the ADC clock source in RCC_CCIPR.
@ 4. Taking the ADC out of deep power-down mode.
@ 5. Enabling the ADC voltage regulator and waiting for stabilization.
@ 6. Performing ADC calibration (ADCAL) and waiting for completion.
@ 7. Enabling the ADC (ADEN) and waiting for it to be ready (ADRDY).
@ 8. Configuring ADC1 Channel 1 (connected to PA0) as the first in the regular sequence (ADC_SQR1).
@ 9. Setting the sample time for Channel 1 in ADC_SMPR1.
@======================================================================
    .global ADC_init
    .thumb_func
ADC_init:
    push {r7, lr}

    bl initPA0
    MOV_imm32 r3, RCC_BASE
    ldr r1, [r3, #AHB2ENR]
    orr r1, r1, #ADCEN
    str r1, [r3, #AHB2ENR]

    ldr r1, [r3, #RCC_CCIPR]
    bic r1, r1, #(0b11 << 28)
    orr r1, r1, #ADC12SEL
    str r1, [r3, #RCC_CCIPR]

    MOV_imm32 r3, ADC1_BASE
    ldr r1, [r3, #ADC_CR]
    bic r1, r1, #DEEPPWD
    str r1, [r3, #ADC_CR]

    ldr r1, [r3, #ADC_CR]
    orr r1, r1, #ADVREGEN
    str r1, [r3, #ADC_CR]

    mov r2, #0xFFFF
delay_loop:
    subs r2, r2, #1
    bne  delay_loop

    ldr r1, [r3, #ADC_CR]
    orr r1, r1, #ADCAL
    str r1, [r3, #ADC_CR]

wait_Calibration:
    ldr r1, [r3, #ADC_CR]
    tst r1, #ADCAL
    bne wait_Calibration

    ldr r1, [r3, #ADC_CR]
    orr r1, r1, #ADEN
    str r1, [r3, #ADC_CR]

wait_ADC_ready:
    ldr r1, [r3, #ADC_ISR]
    tst r1, #ADRDY
    beq wait_ADC_ready

    ldr r1, [r3, #ADC_SQR1]
    bic r1, r1, #(0x1F << 6)
    orr r1, r1, #(1 << 6)
    str r1, [r3, #ADC_SQR1]

    ldr r1, [r3, #0x14]
    bic r1, r1, #(0x7 << (1*3))
    orr r1, r1, #(0x7 << (1*3))
    str r1, [r3, #0x14]

    pop {r7, pc}
@======================================================================
@ initPA0: Initializes GPIO Pin PA0 for analog input.
@ 1. Enables the clock for GPIO Port A via RCC_AHB2ENR.
@ 2. Configures PA0 to Analog Mode in GPIOA_MODER.
@ 3. Disables pull-up/pull-down resistors for PA0 in GPIOA_PUPDR.
@======================================================================
.thumb_func
initPA0:
    push {r7, lr}

    MOV_imm32 r3, RCC_BASE
    ldr r1, [r3, #AHB2ENR]
    orr r1, r1, #GPIOAEN
    str r1, [r3, #AHB2ENR]

    MOV_imm32 r3, GPIOA_BASE
    ldr r1, [r3, #MODER]
    bic r1, r1, #(0b11 << (PA0 * 2))
    orr r1, r1, #(0b11 << (PA0 * 2))
    str r1, [r3, #MODER]

    ldr r1, [r3, #0x0C]
    bic r1, r1, #(0b11 << (PA0 * 2))
    str r1, [r3, #0x0C]

    pop {r7, pc}

@======================================================================
@ report_ADC_amp: Reads the ADC value from PA0 and posts it to the console.
@ This function first calls 'report' to get the current ADC reading.
@ Then, it calls 'insert_hex_into_stopmsg' to format this reading into
@ a string like "Output Vx from ADC 0xNNN". Finally, it posts this
@ formatted message to the console. Corresponds to command 0x01.
@======================================================================
.global report_ADC_amp
.thumb_func
report_ADC_amp:
    bl report
    bl insert_hex_into_stopmsg
    MOV_imm32 r0, device5_voltage_reportmsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost
    mov r0, #0
    pop {r7, pc}

@======================================================================
@ report: Performs a single ADC conversion and returns the 12-bit result.
@ 1. Starts an ADC conversion by setting ADSTART in ADC_CR.
@ 2. Waits for the End Of Conversion (EOC) flag in ADC_ISR.
@ 3. Reads the raw data from ADC_DR.
@ 4. Masks the data to ensure it's a 12-bit value (0x000-0xFFF).
@ 5. Calls 'pull_up_down' (external function, potentially for scaling or specific logic).
@ r0: Returns the processed 12-bit ADC value.
@======================================================================
.global report
.thumb_func
report:
    push {r7, lr}

    MOV_imm32 r3, ADC1_BASE

    ldr r1, [r3, #ADC_CR]
    orr r1, r1, #ADSTART
    str r1, [r3, #ADC_CR]

wait_conversion:
    ldr r1, [r3, #ADC_ISR]
    tst r1, #EOC
    beq wait_conversion

    ldr r0, [r3, #ADC_DR]
    ldr r1, =0x0FFF
    ands r0, r0, r1
	bl pull_up_down
    pop {r7, pc}

@======================================================================
@ device5_checklimits: Sets up ADC monitoring against specified thresholds.
@ It retrieves a 16-bit lower threshold (V_low) and a 16-bit upper
@ threshold (V_high) from the command payload. These thresholds are
@ stored in device-specific memory (device5_BELOW and device5_ABOVE).
@ It then schedules 'device5_EQUALtask' to begin monitoring and posts
@ "ADC Range Monitor is On" to the console. Corresponds to command 0x02.
@ r0: Pointer to command payload containing V_low and V_high.
@======================================================================
.global device5_checklimits
.thumb_func
device5_checklimits:
    ldrh  r1, [r0], #2
    bl    swap_low2bytes_r1
    str   r1, [rDEVP, #device5_BELOW]
    ldrh  r1, [r0], #2
    bl    swap_low2bytes_r1
    str   r1, [rDEVP, #device5_ABOVE]

    MOV_imm32 r0, device5_EQUALtask
    mov   r1, #NULL
    bl    MoT_taskUpdate

	MOV_imm32 r0, device5_monitormsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost
    pop {r7, pc}

@======================================================================
@ device5_stop_monitor: Stops any active ADC monitoring task.
@ It achieves this by scheduling 'device5_skiptask' as the current
@ MoT task for Device 5, effectively replacing any active monitoring
@ (e.g device5_EQUALtask). It then posts "Monitor Has Stopped" to
@ the console. Corresponds to command 0x03.
@======================================================================
.global device5_stop_monitor
.thumb_func
device5_stop_monitor:
    MOV_imm32 r0, device5_skiptask
    mov r1, #NULL
    bl MoT_taskUpdate
    mov r0, #0
    MOV_imm32 r0, device5_stop_monitor_return_resutlsmsg
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    mov r0, #0
    pop {r7, pc}

@======================================================================
@ device5_EQUALtask: Monitors the ADC value while it is within the defined limits.
@ This task periodically reads the ADC value.
@ - If the value exceeds 'device5_ABOVE', it posts "ABOVE LIMIT" and schedules 'device5_ABOVEtask'.
@ - If the value falls below 'device5_BELOW', it posts "BELOW LIMIT" and schedules 'device5_BELOWtask'.
@ - Otherwise (value is within limits), it reschedules itself ('device5_EQUALtask').
@ After handling its logic, it passes control to the next MoT task.
@======================================================================
.global device5_EQUALtask
.thumb_func
device5_EQUALtask:
    bl report

    ldr r1, [rDEVP, #device5_ABOVE]
    cmp r0, r1
    bgt cross_above

    ldr r2, [rDEVP, #device5_BELOW]
    cmp r0, r2
    blt cross_below

    MOV_imm32 r0, device5_EQUALtask
    mov r1, #NULL
    bl MoT_taskUpdate

    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

cross_above:
    MOV_imm32 r0, device5_abovemsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost

    MOV_imm32 r0, device5_ABOVEtask
    mov r1, #NULL
    bl MoT_taskUpdate

    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

cross_below:
    MOV_imm32 r0, device5_belowmsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost

    MOV_imm32 r0, device5_BELOWtask
    mov r1, #NULL
    bl MoT_taskUpdate

    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

@======================================================================
@ device5_ABOVEtask: Monitors the ADC value while it is above the upper threshold.
@ This task periodically reads the ADC value.
@ - If the value drops to or below 'device5_ABOVE':
@   - If it further drops below 'device5_BELOW', posts "BELOW LIMIT" and schedules 'device5_BELOWtask'.
@   - Otherwise (back in range), schedules 'device5_EQUALtask'.
@ - If the value remains above 'device5_ABOVE', it reschedules itself ('device5_ABOVEtask').
@ After handling its logic, it passes control to the next MoT task.
@======================================================================
.global device5_ABOVEtask
.thumb_func
device5_ABOVEtask:
    bl report

    ldr r1, [rDEVP, #device5_ABOVE]
    cmp r0, r1
    ble crossed_back_inside

    MOV_imm32 r0, device5_ABOVEtask
    mov r1, #NULL
    bl MoT_taskUpdate

    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

crossed_back_inside:
    ldr r2, [rDEVP, #device5_BELOW]
    cmp r0, r2
    blt cross_below_from_above

    MOV_imm32 r0, device5_EQUALtask
    mov r1, #NULL
    bl MoT_taskUpdate

    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

cross_below_from_above:
    MOV_imm32 r0, device5_belowmsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost

    MOV_imm32 r0, device5_BELOWtask
    mov r1, #NULL
    bl MoT_taskUpdate

    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

@======================================================================
@ device5_BELOWtask: Monitors the ADC value while it is below the lower threshold.
@ This task periodically reads the ADC value.
@ - If the value rises to or above 'device5_BELOW':
@   - If it further rises above 'device5_ABOVE', posts "ABOVE LIMIT" and schedules 'device5_ABOVEtask'.
@   - Otherwise (back in range), schedules 'device5_EQUALtask'.
@ - If the value remains below 'device5_BELOW', it reschedules itself ('device5_BELOWtask').
@ After handling its logic, it passes control to the next MoT task.
@======================================================================
.global device5_BELOWtask
.thumb_func
device5_BELOWtask:
    bl report

    ldr r2, [rDEVP, #device5_BELOW]
    cmp r0, r2
    bge crossed_back_inside_below

    MOV_imm32 r0, device5_BELOWtask
    mov r1, #NULL
    bl MoT_taskUpdate

    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

crossed_back_inside_below:
    ldr r1, [rDEVP, #device5_ABOVE]
    cmp r0, r1
    bgt cross_above_from_below

    MOV_imm32 r0, device5_EQUALtask
    mov r1, #NULL
    bl MoT_taskUpdate

    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

cross_above_from_below:
    MOV_imm32 r0, device5_abovemsg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost

    MOV_imm32 r0, device5_ABOVEtask
    mov r1, #NULL
    bl MoT_taskUpdate

    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]


@======================================================================
@ device5_skiptask: A minimal MoT task that does nothing for Device 5.
@ Its sole purpose is to pass execution control to the next scheduled
@ MoT task in the system. This is often used as the default task or
@ to explicitly stop other device-specific periodic tasks.
@======================================================================
.global device5_skiptask
.thumb_func
device5_skiptask:
    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]


@======================================================================
@ insert_hex_into_stopmsg: Formats a 12-bit ADC value into a message string.
@ The function takes the ADC value (expected in r0 after 'report' and
@ 'pull_up_down' calls) and converts its lower three hexadecimal nibbles
@ (12 bits) into ASCII characters. These characters are then inserted
@ into the "Output Vx from ADC 0xNNN" placeholder in the
@ 'device5_voltage_reporttxt' string.
@ r0: Input ADC value (12-bit).
@======================================================================
.global insert_hex_into_stopmsg
.thumb_func
insert_hex_into_stopmsg:
    push {r4-r7, lr}

    MOV_imm32 r3, device5_voltage_reportmsg
    add r3, r3, #48
    add r3, r3, #2

    mov r4, r0

    lsrs r5, r4, #8
    and r5, r5, #0xF
    bl nibble_to_ascii
    strb r0, [r3], #1

    lsrs r5, r4, #4
    and r5, r5, #0xF
    bl nibble_to_ascii
    strb r0, [r3], #1

    mov r5, r4
    and r5, r5, #0xF
    bl nibble_to_ascii
    strb r0, [r3], #1

    pop {r4-r7, pc}
