#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

.extern trigger_state

.syntax unified
.thumb
.text

@======================================================================
@ device4_cmdHandler: Command dispatcher for Device 4 (DAC).
@ It reads the command ID byte from the MoT message payload (pointed to by r0),
@ masks it to ensure it's within the valid range (0-15), and then uses
@ a table branch (TBB) instruction to jump to the corresponding command
@ handling routine listed in the 'device4_cmds' table.
@ r0: Pointer to MoT command payload; first byte is command ID.
@ r1: Used to store and manipulate the command ID.
@======================================================================
.global device4_cmdHandler
.thumb_func
device4_cmdHandler:
    push   {r7, lr}
    ldrb   r1, [r0], #1
    and    r1, r1, #0x0F
    tbb    [pc, r1]
device4_cmds:
    .byte  (device4_initialize      - device4_cmds)/2
    .byte  (device4_constvol        - device4_cmds)/2
    .byte  (device4_transvol        - device4_cmds)/2
    .byte  (device4_stop_periodictask - device4_cmds)/2
    .byte  (device4_trig_on - device4_cmds)/2

MoT_core_m device4, device4_cmdHandler, device4_skiptask
MoT_varAlloc_m device4_value,      device4_VALUE
MoT_varAlloc_m device4_target,     device4_TARGET
MoT_varAlloc_m device4_cyclecount, device4_CYCLES
MoT_varAlloc_m device4_reload,     device4_RELOAD
MoT_varAlloc_m device4_count,      device4_COUNT

MoT_msgLink_m device4_initmsg,  device4_inittxt,  device4_initmsglen
device4_inittxt:
    .ascii "device4 has been initialized\n\r\0"
.equ device4_initmsglen, (. - device4_inittxt)

MoT_msgLink_m device4_constval, device4_constxt,  device4_consmsglen
device4_constxt:
    .ascii "device4 set to constant voltage\n\r\0"
.equ device4_consmsglen, (. - device4_constxt)

MoT_msgLink_m device4_trans2,   device4_trans2txt, device4_trans2len
device4_trans2txt:
    .ascii "Voltage transitioned\n\r\0"
.equ device4_trans2len, (. - device4_trans2txt)

MoT_msgLink_m device4_stopmsg,  device4_stoptxt,   device4_stopmsglen
device4_stoptxt:
    .ascii "device4 has stopped outputing a periodic signal\n\r\0"
.equ device4_stopmsglen, (. - device4_stoptxt)

MoT_msgLink_m device4_trigmsg,  device4_trigtxt,   device4_trigmsglen
device4_trigtxt:
    .ascii "device4 Trigger Enabled on PA1\n\r\0"
.equ device4_trigmsglen, (. - device4_trigtxt)

@======================================================================
@ device4_initialize: Initializes Device 4 (DAC1 Channel 2 on PA5). (Command 0x00)
@ This function calls 'DAC1_CH2_init' to perform the hardware setup for the
@ DAC peripheral and the associated GPIO pin PA5. After successful initialization,
@ it posts the message "device4 has been initialized" to the console.
@======================================================================
.global device4_initialize
.thumb_func
device4_initialize:
    bl    DAC1_CH2_init
    add   r0, rDEVP, #device4_initmsg_OFFSET
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}

@======================================================================
@ device4_trig_on: Enables external trigger mode for Device 4 (DAC). (Command 0x04)
@ It sets the global 'trigger_state' variable to 1, indicating that Device 4
@ should handle EXTI1 interrupts. It then calls 'EXTI1_init' to configure
@ GPIO PA1 as an external interrupt source.
@ Finally, it posts the message "device4 Trigger Enabled on PA1" to the console.
@ The actual voltage to be output on trigger is expected to be pre-configured
@ or handled by the EXTI1 interrupt handler logic.
@======================================================================
.global device4_trig_on
.thumb_func
device4_trig_on:
	ldr r3, =trigger_state
	mov r1, #1
	str r1, [r3]
    bl    EXTI1_init
    add   r0, rDEVP, #device4_trigmsg_OFFSET
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}
@======================================================================
@ device4_constvol: Sets a constant DC voltage output on DAC1 Channel 2. (Command 0x01)
@ It reads a 16-bit value (expected to be a 12-bit DAC value) from the command
@ payload pointed to by r0, performs an endian swap if necessary, and then
@ calls 'DAC1_CH2_output' to set the DAC output. After setting the voltage,
@ it posts the message "device4 set to constant voltage" to the console.
@ r0: Input, pointer to command payload containing 16-bit voltage argument.
@     Output (for MoT_msgPost), pointer to message link.
@======================================================================
.global device4_constvol
.thumb_func
device4_constvol:
    ldrh  r1, [r0]
    bl    swap_low2bytes_r1
    mov   r0, r1
    bl    DAC1_CH2_output
    MOV_imm32 r0, device4_constval
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}

@======================================================================
@ device4_transvol: Starts a periodic square waveform output on DAC1 Channel 2. (Command 0x02)
@ It reads four 16-bit parameters from the command payload:
@   Va (initial/first voltage level, 12-bit value)
@   T1 (duration for Va)
@   Vb (second voltage level, 12-bit value)
@   T2 (duration for Vb)
@ These values are stored in device-specific memory slots (device4_VALUE for Va,
@ device4_CYCLES for T1, device4_TARGET for Vb, device4_RELOAD for T2).
@ The 'device4_COUNT' is initialized with T2. It then schedules 'device4_ONtask'
@ to begin the waveform generation and posts "Voltage transitioned" to the console.
@ r0: Input, pointer to command payload. Output (for MoT_msgPost), pointer to message link.
@======================================================================
.global device4_transvol
.thumb_func
device4_transvol:
    ldrh  r1, [r0], #2
    bl    swap_low2bytes_r1
    str   r1, [rDEVP, #device4_VALUE]
    ldrh  r1, [r0], #2
    bl    swap_low2bytes_r1
    str   r1, [rDEVP, #device4_CYCLES]
    ldrh  r1, [r0], #2
    bl    swap_low2bytes_r1
    str   r1, [rDEVP, #device4_TARGET]
    ldrh  r1, [r0], #2
    bl    swap_low2bytes_r1
    str   r1, [rDEVP, #device4_RELOAD]
    str   r1, [rDEVP, #device4_COUNT]
    MOV_imm32 r0, device4_ONtask
    mov   r1, #NULL
    bl    MoT_taskUpdate
    MOV_imm32 r0, device4_trans2
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}

@======================================================================
@ device4_ONtask: MoT task for the 'ON' phase of the periodic DAC waveform.
@ This task is part of the periodic signal generation. It decrements a
@ countdown timer ('device4_COUNT').
@ When the countdown reaches zero:
@   1. Outputs voltage Va (stored in 'device4_VALUE') using 'DAC1_CH2_output'.
@   2. Resets 'device4_COUNT' with duration T1 (stored in 'device4_CYCLES').
@   3. Schedules 'device4_OFFtask' as the next task.
@======================================================================
.global device4_ONtask
.thumb_func
device4_ONtask:
    ldr r1, [rDEVP, #device4_COUNT]
    subs r1, r1, #1
    str r1, [rDEVP, #device4_COUNT]
    cbnz r1, 1f
    ldr r0, [rDEVP, #device4_VALUE]
    bl  DAC1_CH2_output
    ldr r1, [rDEVP, #device4_CYCLES]
    str r1, [rDEVP, #device4_COUNT]
    MOV_imm32 r0, device4_OFFtask
    mov r1, #NULL
    bl  MoT_taskUpdate
1:
    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

@======================================================================
@ device4_OFFtask: MoT task for the 'OFF' phase of the periodic DAC waveform.
@ This task is part of the periodic signal generation. It decrements a
@ countdown timer ('device4_COUNT').
@ When the countdown reaches zero:
@   1. Outputs voltage Vb (stored in 'device4_TARGET') using 'DAC1_CH2_output'.
@   2. Resets 'device4_COUNT' with duration T2 (stored in 'device4_RELOAD').
@   3. Schedules 'device4_ONtask' as the next task.
@======================================================================
.global device4_OFFtask
.thumb_func
device4_OFFtask:
    ldr r1, [rDEVP, #device4_COUNT]
    subs r1, r1, #1
    str r1, [rDEVP, #device4_COUNT]
    cbnz r1, 1f
    ldr r0, [rDEVP, #device4_TARGET]
    bl  DAC1_CH2_output
    ldr r1, [rDEVP, #device4_RELOAD]
    str r1, [rDEVP, #device4_COUNT]
    MOV_imm32 r0, device4_ONtask
    mov r1, #NULL
    bl  MoT_taskUpdate
1:
    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

@======================================================================
@ device4_stop_periodictask: Stops the ongoing periodic DAC waveform. (Command 0x03)
@ It cancels the current periodic task (e.g., 'device4_ONtask' or 'device4_OFFtask')
@ by scheduling 'device4_skiptask' in its place.
@ It then sets the DAC output to 0 Volts by calling 'DAC1_CH2_output' with 0.
@ Finally, it posts the message "device4 has stopped outputing a periodic signal"
@ to the console.
@======================================================================
.global device4_stop_periodictask
.thumb_func
device4_stop_periodictask:
    MOV_imm32 r0, device4_skiptask
    mov r1, #NULL
    bl MoT_taskUpdate
    mov r0, #0
    bl DAC1_CH2_output
    MOV_imm32 r0, device4_stopmsg
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    mov r0, #0
    pop {r7, pc}

@======================================================================
@ device4_skiptask: A minimal MoT task that performs no specific action for Device 4.
@ Its purpose is to act as a placeholder or default task. It immediately
@ passes execution control to the next scheduled MoT task in the system
@ by loading the next task's context (rDEVP) and jumping to its execution address.
@======================================================================
.global device4_skiptask
.thumb_func
device4_skiptask:
    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

@======================================================================
@ PA5init: Initializes GPIO Pin PA5 for analog output (DAC1_OUT2).
@ 1. Enables the clock for GPIO Port A via the RCC_AHB2ENR register.
@ 2. Configures Pin PA5 to Analog Mode by setting the appropriate bits
@    in the GPIOA_MODER register. This makes the pin suitable for use
@    by the DAC peripheral.
@======================================================================
.global PA5init
.thumb_func
PA5init:
    push   {r7, lr}
    MOV_imm32 r3, RCC_BASE
    ldr    r1, [r3, #AHB2ENR]
    orr    r1, r1, #GPIOAEN
    str    r1, [r3, #AHB2ENR]
    MOV_imm32 r3, GPIOA_BASE
    ldr    r1, [r3, #MODER]
    bic    r1, r1, #(0b11 << (5*2))
    orr    r1, r1, #(0b11 << (5*2))
    str    r1, [r3, #MODER]
    pop    {r7, pc}

@======================================================================
@ DAC1_CH2_init: Initializes DAC1 Channel 2 for analog output.
@ 1. Calls 'PA5init' to configure GPIO PA5 (DAC1_OUT2) for analog mode.
@ 2. Enables the clock for the DAC1 peripheral via RCC_AHB2ENR.
@ 3. Resets the DAC1 peripheral using RCC_AHB2RSTR to ensure a known state.
@ 4. Enables DAC1 Channel 2 by setting the EN2 bit in the DAC_CR register.
@======================================================================
.global DAC1_CH2_init
.thumb_func
DAC1_CH2_init:
    push   {r7, lr}
    bl     PA5init
    MOV_imm32 r3, RCC_BASE
    ldr    r1, [r3, #AHB2ENR]
    orr    r1, r1, #DAC1EN
    str    r1, [r3, #AHB2ENR]
    ldr    r1, [r3, #AHB2RSTR]
    orr    r1, r1, #DAC1RST
    str    r1, [r3, #AHB2RSTR]
    bic    r1, r1, #DAC1RST
    str    r1, [r3, #AHB2RSTR]
    MOV_imm32 r3, DAC1_BASE
    ldr    r1, [r3, #CR]
    orr    r1, r1, #CR_EN2
    str    r1, [r3, #CR]
    pop    {r7, pc}

@======================================================================
@ DAC1_CH2_output: Writes a 12-bit digital value to DAC1 Channel 2.
@ The function takes the 12-bit value to be converted in register r0.
@ It directly writes this value to the DAC1 Channel 2 12-bit Right-aligned
@ Data Holding Register (DAC_DHR12R2). This action updates the voltage
@ output on pin PA5, assuming the DAC channel is enabled and appropriately configured
@ (e.g., for software trigger if TEN2 is set, or direct update).
@ r0: Input, the 12-bit value to output (0x000 to 0xFFF).
@======================================================================
.global DAC1_CH2_output
.thumb_func
DAC1_CH2_output:
    push   {r7, lr}
    MOV_imm32 r3, DAC1_BASE
    str    r0, [r3, #DAC_DHR12R2]
    pop    {r7, pc}
