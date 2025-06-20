#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

.syntax unified
.thumb

.extern trigger_state

.data
.global temp_pwm_arr_val
temp_pwm_arr_val: .word 1999999
.global temp_pwm_arr_duty
temp_pwm_arr_duty: .word 50
.global temp_opm_delay_ticks_val
temp_opm_delay_ticks_val: .word 1999999
.global temp_opm_width_ticks_val
temp_opm_width_ticks_val: .word 1999999
.global temp_pfm_fixed_pulse_width_ticks_val
temp_pfm_fixed_pulse_width_ticks_val: .word 1000
.global temp_pfm_current_arr_val
temp_pfm_current_arr_val: .word 9999
.global temp_single_freq_cycle_target_hz_val
temp_single_freq_cycle_target_hz_val: .word 2
.global temp_simple_pulse_width_ticks_val
temp_simple_pulse_width_ticks_val: .word 250000
.text

@======================================================================
@ store_pwm_cmd: Stores PWM parameters for a triggered operation.
@ This function is called by 'prep_trig' when arming a triggered PWM output.
@ It retrieves a 32-bit Auto-Reload Register (ARR) value and a 16-bit duty
@ cycle percentage from the command payload (pointed to by r0, via 'arg_retrieve'
@ and 'arg_retrieve_half'). These parameters are then stored in the
@ temporary global variables 'temp_pwm_arr_val' and 'temp_pwm_arr_duty'
@ respectively. These temporary values will be used by the EXTI1 interrupt
@ handler to configure and start PWM when the trigger occurs.
@ r0: Input, pointer to the command payload containing PWM parameters.
@     Is updated by arg_retrieve/arg_retrieve_half.
@======================================================================
.global store_pwm_cmd
.thumb_func
store_pwm_cmd:
	push {r0-r7, lr}
	
	bl arg_retrieve
    ldr r6, =temp_pwm_arr_val
	str r1, [r6]

	bl arg_retrieve_half
	ldr r6, =temp_pwm_arr_duty
	str r1, [r6]
	
	pop {r0-r7, pc}

@======================================================================
@ store_pfm_cmd: Stores PFM parameters for a triggered operation.
@ Called by 'prep_trig' for arming triggered Pulse Frequency Modulation.
@ It retrieves a 32-bit target frequency (in Hz) from the command payload
@ using 'arg_retrieve'. This frequency is converted to an ARR value (period in
@ timer ticks) using 'freq_to_arr_ticks'. The resulting ARR is stored in
@ 'temp_pwm_arr_val' (as PFM is implemented via PWM hardware). A fixed 50%
@ duty cycle is then stored in 'temp_pwm_arr_duty'. These temporary values
@ are used by the EXTI1 handler upon trigger.
@ r0: Input, pointer to command payload. Output from freq_to_arr_ticks (ARR value).
@======================================================================
.global store_pfm_cmd
.thumb_func
store_pfm_cmd:
	push {r0-r7, lr}
	
	bl arg_retrieve
    mov r0, r1
    bl freq_to_arr_ticks
    ldr r6, =temp_pwm_arr_val
	str r0, [r6]

	mov r1, #50
    ldr r6, =temp_pwm_arr_duty
	str r1, [r6]
	
	pop {r0-r7, pc}
	
@======================================================================
@ store_sp_cmd: Stores Simple Pulse parameters for a triggered operation.
@ Called by 'prep_trig' for arming a triggered Simple Pulse output.
@ It retrieves a 32-bit pulse width (in timer ticks) from the command
@ payload using 'arg_retrieve'. This width is stored in the temporary
@ global variable 'temp_simple_pulse_width_ticks_val'. This value will be
@ used by the EXTI1 interrupt handler to generate the pulse.
@ r0: Input, pointer to command payload.
@======================================================================
.global store_sp_cmd
.thumb_func
store_sp_cmd:
	push {r0-r7, lr}
	
	bl arg_retrieve
    ldr r6, =temp_simple_pulse_width_ticks_val
	str r1, [r6]
	
	pop {r0-r7, pc}

@======================================================================
@ store_pw_cmd: Stores Pulse Width (OPM) parameters for a triggered operation.
@ Called by 'prep_trig' for arming a triggered One-Pulse Mode (OPM) output
@ which includes an initial delay and a pulse width.
@ It retrieves a 32-bit delay value (in ticks) and a 32-bit pulse width
@ value (in ticks) from the command payload using 'arg_retrieve' (called twice).
@ These are stored in 'temp_opm_delay_ticks_val' and 'temp_opm_width_ticks_val'
@ respectively, for use by the EXTI1 interrupt handler.
@ r0: Input, pointer to command payload. Updated by arg_retrieve.
@======================================================================
.global store_pw_cmd
.thumb_func
store_pw_cmd:
	push {r0-r7, lr}
	
	bl arg_retrieve
    ldr r6, =temp_opm_delay_ticks_val
	str r1, [r6]

	bl arg_retrieve
    ldr r6, =temp_opm_width_ticks_val
	str r1, [r6]
	
	pop {r0-r7, pc}

@======================================================================
@ store_pf_cmd: Stores Pulse Frequency parameters for a triggered operation.
@ Called by 'prep_trig' for arming a triggered single cycle pulse at a
@ specified frequency.
@ It retrieves a 32-bit target frequency (in Hz) from the command payload
@ using 'arg_retrieve'. This frequency is stored in the temporary global
@ variable 'temp_single_freq_cycle_target_hz_val' for use by the EXTI1
@ interrupt handler to generate one cycle of the specified frequency.
@ r0: Input, pointer to command payload.
@======================================================================
.global store_pf_cmd
.thumb_func
store_pf_cmd:
	push {r0-r7, lr}
	
	bl arg_retrieve
    ldr r6, =temp_single_freq_cycle_target_hz_val
	str r1, [r6]
	
	pop {r0-r7, pc}

@======================================================================
@ prep_trig: Prepares Device 6 (Timer) for a triggered operation.
@ This function is called when a "Device 6 Triggered" command (Cmd 0x07) is received.
@ It reads a sub-command byte from the MoT command payload (pointed to by r0)
@ to determine which specific timer function (PWM, PFM, Simple Pulse,
@ Pulse Width/OPM, or Pulse Frequency) to arm.
@ Based on the sub-command:
@ - It sets the global 'trigger_state' variable to a unique value (3 for PWM,
@   4 for PFM, 5 for Simple Pulse, 6 for Pulse Width, 7 for Pulse Frequency).
@   This state is used by the EXTI1_IRQHandler to dispatch to the correct
@   Device 6 specific handler.
@ - It calls the corresponding 'store_<type>_cmd' function (e.g., 'store_pwm_cmd')
@   to parse the remaining parameters from the command payload and store them
@   in temporary global variables.
@ r0: Input, pointer to command payload. First byte is sub-command, followed by parameters.
@======================================================================
.global prep_trig
.thumb_func
prep_trig:
	push {r0-r7, lr}
	ldrb r1, [r0], #1

	cmp r1, #1
	beq pwd
 	cmp r1, #2
	beq pfm
	cmp r1, #3
	beq sp
	cmp r1, #4
	beq pw
	cmp r1, #5
	beq pf
	b done
pwd:
	ldr r5, =trigger_state
	mov r4, #3
	str r4, [r5]
	bl store_pwm_cmd
	b done

pfm:
	ldr r5, =trigger_state
	mov r4, #4
	str r4, [r5]
	bl store_pfm_cmd
	b done

sp:
	ldr r5, =trigger_state
	mov r4, #5
	str r4, [r5]
	bl store_sp_cmd
	b done

pw:
	ldr r5, =trigger_state
	mov r4, #6
	str r4, [r5]
	bl store_pw_cmd
	b done

pf:
	ldr r5, =trigger_state
	mov r4, #7
	str r4, [r5]
	bl store_pf_cmd
	b done

done:
	pop {r0-r7, pc}
