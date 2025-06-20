#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

.syntax unified
.thumb

.extern trigger_state

.data
device4_TRIG_VAL:   .word 0

.text
@======================================================================
@ EXTI1_init: Initializes External Interrupt Line 1 (EXTI1) on GPIO Pin PA1.
@ This function configures PA1 as an input with a pull-down resistor and sets up
@ the necessary system configurations (SYSCFG) to map PA1 to EXTI1.
@ It enables the EXTI1 interrupt, configures it for a rising edge trigger,
@ clears any pending flags, and enables the EXTI1 interrupt in the NVIC.
@ If the global 'trigger_state' is 1 (indicating Device 4 - DAC context),
@ it first attempts to load a 16-bit value from the address in r0 (command payload)
@ and stores it into 'device4_TRIG_VAL', presumably as a pre-loaded DAC value for the trigger.
@ r0: May point to a 16-bit DAC value if trigger_state indicates Device 4.
@======================================================================
.global EXTI1_init
.thumb_func
EXTI1_init:
     push {r7, lr}

	ldr r4, =trigger_state
	ldr r1, [r4]
	cmp r1, #1
	bne Rest_and_DAC

DAC_specific:
	ldrh  r1, [r0], #2
    bl    swap_low2bytes_r1
    ldr   r2, =device4_TRIG_VAL
    str   r1, [r2]

Rest_and_DAC:
    MOV_imm32 r3, RCC_BASE
    ldr     r1, [r3, #AHB2ENR]
    orr     r1, r1, #GPIOAEN
    str     r1, [r3, #AHB2ENR]

    MOV_imm32 r3, GPIOA_BASE
    ldr     r1, [r3, #MODER]
    bic     r1, r1, #(0b11 << 2)
    str     r1, [r3, #MODER]

    ldr     r1, [r3, #0x0C]
    bic     r1, r1, #(0b11 << 2)
    orr     r1, r1, #(0b10 << 2)
    str     r1, [r3, #0x0C]

    MOV_imm32 r3, RCC_BASE
    ldr     r1, [r3, #0x60]
    orr     r1, r1, #(1 << 0)
    str     r1, [r3, #0x60]

    MOV_imm32 r3, 0x40010000
    movs    r1, #0
    str     r1, [r3, #0x08]

    MOV_imm32 r3, 0x40010400

    ldr     r1, [r3, #0x00]
    orr     r1, r1, #(1 << 1)
    str     r1, [r3, #0x00]

    ldr     r1, [r3, #0x08]
    orr     r1, r1, #(1 << 1)
    str     r1, [r3, #0x08]

    movs    r1, #(1 << 1)
    str     r1, [r3, #0x14]

    movs    r0, #7
    movs    r1, #1
    lsl     r1, r1, r0
    ldr     r2, =0xE000E100
    str     r1, [r2]

    pop {r7, pc}

@======================================================================
@ EXTI1_IRQHandler: Interrupt handler for External Interrupt Line 1 (EXTI1).
@ This function is invoked when an interrupt occurs on EXTI Line 1 (PA1).
@ It first clears the EXTI1 pending interrupt flag to prevent re-triggering.
@ Then, it reads the global 'trigger_state' variable to determine which
@ device or functionality should handle this specific interrupt.
@ Based on 'trigger_state':
@ - 1: Branches to 'device4_EXTI1_IRQHandler' (DAC triggered output).
@ - 2: Branches to 'device5_EXTI1_IRQHandler' (ADC triggered operation).
@ - 8: Branches to 'device3_cmd_8_EXTI1_IRQHandler' (GPIO triggered input read).
@ - 3-7: Calls 'device6_timer_output_disable', then branches to the
@        corresponding 'device6_cmd_X_EXTI1_IRQHandler' for triggered Timer operations.
@ Registers r0-r7 and lr are saved and restored.
@======================================================================
 .global EXTI1_IRQHandler
.thumb_func
EXTI1_IRQHandler:
    push {r0-r7, lr}
	mov r0, #100
	bl delay
    MOVW    r0, #:lower16:0x40010414
    MOVT    r0, #:upper16:0x40010414
    movs    r1, #(1 << 1)
    str     r1, [r0]

	ldr r0, =trigger_state
	ldr r1, [r0]
	cmp r1, #1
	beq device4_EXTI1_IRQHandler

	cmp r1, #2
	beq device5_EXTI1_IRQHandler

	cmp r1, #8
	beq device3_cmd_8_EXTI1_IRQHandler

	bl device6_timer_output_disable
	cmp r1, #3
	beq device6_cmd_1_EXTI1_IRQHandler

	cmp r1, #4
	beq device6_cmd_2_EXTI1_IRQHandler

	cmp r1, #5
	beq device6_cmd_3_EXTI1_IRQHandler

	cmp r1, #6
	beq device6_cmd_4_EXTI1_IRQHandler

	cmp r1, #7
	beq device6_cmd_5_EXTI1_IRQHandler

    pop {r0-r7, pc}

@======================================================================
@ device4_EXTI1_IRQHandler: EXTI1 interrupt handler specific to Device 4 (DAC).
@ This function is called by EXTI1_IRQHandler when 'trigger_state' is 1.
@ It reads a pre-loaded 12-bit DAC value from the global variable
@ 'device4_TRIG_VAL' and then calls 'DAC1_CH2_output' to output this
@ voltage on DAC1 Channel 2 (PA5).
@======================================================================
.thumb_func
device4_EXTI1_IRQHandler:
    ldr   r2, =device4_TRIG_VAL
    ldr r0, [r2]
    bl      DAC1_CH2_output
	pop {r0-r7, pc}

@======================================================================
@ device5_EXTI1_IRQHandler: EXTI1 interrupt handler specific to Device 5 (ADC).
@ This function is called by EXTI1_IRQHandler when 'trigger_state' is 2.
@ It then calls 'report_triggered' which handles ADC operations
@ for Device 5 in a triggered context (e.g., performs an ADC read and reports it).
@======================================================================
.thumb_func
device5_EXTI1_IRQHandler:
    bl      report_triggered

@======================================================================
@ device6_cmd_1_EXTI1_IRQHandler: EXTI1 handler for Device 6 (Timer) PWM mode.
@ Called when 'trigger_state' is 3. It copies pre-stored temporary PWM
@ parameters (ARR from 'temp_pwm_arr_val' and Duty from 'temp_pwm_arr_duty')
@ into the active PWM operational variables ('pwm_arr_val', 'pwm_arr_duty').
@ Then, it calls 'device6_pwm_enable' to start or update the PWM signal
@ on TIM2_CH1 (PA5) with these parameters.
@======================================================================
.thumb_func
device6_cmd_1_EXTI1_IRQHandler:
	ldr r6, =temp_pwm_arr_val
	ldr r6, [r6]
	ldr r5, =pwm_arr_val
	str r6, [r5]

	ldr r6, =temp_pwm_arr_duty
	ldrb r6, [r6]
	ldr r5, =pwm_arr_duty
	strb r6, [r5]

	bl device6_pwm_enable
	pop {r0-r7, pc}

@======================================================================
@ device6_cmd_2_EXTI1_IRQHandler: EXTI1 handler for Device 6 (Timer) PFM mode.
@ Called when 'trigger_state' is 4. It copies pre-stored temporary PFM
@ parameters into active operational variables.
@ Then, it calls 'device6_pwm_enable' to start/update the PFM signal.
@======================================================================
.thumb_func
device6_cmd_2_EXTI1_IRQHandler:
	ldr r6, =temp_pwm_arr_val
	ldr r6, [r6]
	ldr r5, =pwm_arr_val
	str r6, [r5]

	ldr r6, =temp_pwm_arr_duty
	ldrb r6, [r6]
	ldr r5, =pwm_arr_duty
	strb r6, [r5]

	bl device6_pwm_enable
	pop {r0-r7, pc}

@======================================================================
@ device6_cmd_3_EXTI1_IRQHandler: EXTI1 handler for Device 6 (Timer) Simple Pulse mode.
@ Called when 'trigger_state' is 5. It copies the pre-stored temporary
@ pulse width (in timer ticks) from 'temp_simple_pulse_width_ticks_val'
@ into the active operational variable 'simple_pulse_width_ticks_val'.
@ Then, it calls 'device6_simple_pulse_enable' to generate a single pulse.
@======================================================================
.thumb_func
device6_cmd_3_EXTI1_IRQHandler:
	ldr r6, =temp_simple_pulse_width_ticks_val
	ldr r6, [r6]
	ldr r5, =simple_pulse_width_ticks_val
	str r6, [r5]

	bl device6_simple_pulse_enable
	pop {r0-r7, pc}

@======================================================================
@ device6_cmd_4_EXTI1_IRQHandler: EXTI1 handler for Device 6 (Timer) Pulse Width (OPM) mode.
@ Called when 'trigger_state' is 6. It copies pre-stored temporary
@ OPM parameters (delay from 'temp_opm_delay_ticks_val' and width from
@ 'temp_opm_width_ticks_val') into active operational variables
@ ('opm_delay_ticks_val', 'opm_width_ticks_val').
@ Then, it calls 'device6_opm_enable' to generate a single pulse with specified delay and width.
@======================================================================
.thumb_func
device6_cmd_4_EXTI1_IRQHandler:
	ldr r6, =temp_opm_delay_ticks_val
	ldr r6, [r6]
	ldr r5, =opm_delay_ticks_val
	str r6, [r5]

	ldr r6, =temp_opm_width_ticks_val
	ldr r6, [r6]
	ldr r5, =opm_width_ticks_val
	str r6, [r5]

	bl device6_opm_enable
	pop {r0-r7, pc}

@======================================================================
@ device6_cmd_5_EXTI1_IRQHandler: EXTI1 handler for Device 6 (Timer) Pulse Frequency mode.
@ Called when 'trigger_state' is 7. It copies the pre-stored temporary
@ target frequency (in Hz) from 'temp_single_freq_cycle_target_hz_val'
@ into the active operational variable 'single_freq_cycle_target_hz_val'.
@ Then, it calls 'device6_single_freq_cycle_enable' to generate a single pulse
@ cycle at the specified frequency.
@======================================================================
.thumb_func
device6_cmd_5_EXTI1_IRQHandler:
	ldr r6, =temp_single_freq_cycle_target_hz_val
	ldr r6, [r6]
	ldr r5, =single_freq_cycle_target_hz_val
	str r6, [r5]

	bl device6_single_freq_cycle_enable
	pop {r0-r7, pc}

@======================================================================
@ device3_cmd_8_EXTI1_IRQHandler: EXTI1 interrupt handler specific to Device 3 (GPIO).
@ This function is called by EXTI1_IRQHandler when 'trigger_state' is 8.
@ It then calls 'device3_input_read' to read the state of a GPIO pin
@ The main IRQ handler already saved r0-r7, lr.
@======================================================================
.thumb_func
device3_cmd_8_EXTI1_IRQHandler:
	pop {r0-r6}
	bl device3_input_read

@======================================================================
@ report_triggered: Helper function, for Device 5 (ADC) triggered reads.
@ This function seems to be a wrapper or continuation for ADC reporting
@ in an interrupt context. It pops registers r0-r6 from the stack,
@ then pushes r7 and lr (standard function prologue), and finally branches
@ to 'report_ADC_amp' to perform the ADC reading and reporting.
@======================================================================
.thumb_func
report_triggered:
	pop {r0-r6}
	b report_ADC_amp
