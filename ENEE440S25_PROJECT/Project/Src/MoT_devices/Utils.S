#define __ASSEMBLY__
#include "MoTstructures.h"

.syntax unified
.thumb

.macro MOV_imm32 reg, constant
    movw \reg, #:lower16:\constant
        movt \reg, #:upper16:\constant
    .endm

.text
@======================================================================
@ swap_low2bytes_r1: Swaps the two least significant bytes of register r1.
@ This function takes the 16-bit value in the lower half of r1 (r1[15:0])
@ and swaps its high byte (r1[15:8]) with its low byte (r1[7:0]).
@ For example, if r1 initially holds 0x....ABCD, after the call, the lower
@ 16 bits of r1 will hold 0xCDAB. The upper 16 bits of r1 (if any) are
@ preserved. This is often used for endianness correction when reading
@ 16-bit data from a communication interface or memory where byte order differs.
@ Input:
@   r1: Register containing the value whose lower 16-bit's bytes are to be swapped.
@ Output:
@   r1: The lower 16 bits of r1 are modified with the byte-swapped value.
@======================================================================
.global swap_low2bytes_r1
.thumb_func
swap_low2bytes_r1:
    push {r0, r2, r3, r4, r7, lr}
    mov   r2, r1
    ldr   r4, =0xFFFF
    and   r2, r2, r4
    mov   r3, r2
    lsr   r3, r3, #8
    ldr   r4, =0x00FF
    and   r3, r3, r4
    lsl   r2, r2, #8
    ldr   r4, =0xFF00
    and   r2, r2, r4
    orr   r2, r2, r3
    ldr   r4, =0xFFFF
    bic   r1, r1, r4
    orr   r1, r1, r2
    pop {r0, r2, r3, r4, r7, pc}

@======================================================================
@ nibble_to_ascii: Converts a 4-bit nibble to its ASCII hexadecimal character.
@ This function takes a 4-bit value (0-15 or 0x0-0xF) in the lower bits of
@ register r5 and converts it into its corresponding ASCII hexadecimal
@ character ('0'-'9' or 'A'-'F').
@ Input:
@   r5: The lower 4 bits contain the nibble to be converted.
@ Output:
@   r0: The ASCII character representation of the nibble.
@======================================================================
.global nibble_to_ascii
.thumb_func
nibble_to_ascii:
    cmp r5, #9
    ble is_digit
    add r0, r5, #'A' - 10
    bx lr

is_digit:
    add r0, r5, #'0'
    bx lr

@======================================================================
@ arg_retrieve: Retrieves a 32-bit argument from the command buffer.
@ This function reads two consecutive 16-bit half-words from the memory
@ location pointed to by r0 (command buffer).
@ It calls 'swap_low2bytes_r1' on each half-word to handle potential
@ endianness issues. The two (endian-corrected) half-words are then
@ combined to form the full 32-bit argument.
@ Input:
@   r0: Pointer to the command buffer from which the argument is read.
@       This pointer is advanced by 4 bytes after the operation.
@ Output:
@   r1: The retrieved and byte-swapped 32-bit argument.
@======================================================================
.global arg_retrieve
.thumb_func
arg_retrieve:
	push {r2-r7, lr}

	ldrh  r1, [r0], #2
    bl    swap_low2bytes_r1
    lsl   r1, r1, #16
    mov   r4, r1
	ldrh  r1, [r0], #2
    bl    swap_low2bytes_r1
    orr   r1, r1, r4
	pop {r2-r7, pc}

@======================================================================
@ arg_retrieve_24bits: Retrieves a 24-bit argument from the command buffer.
@ This function reads a 24-bit value from the memory location pointed to by r0.
@ The 16-bit half-word is read first and byte-swapped using 'swap_low2bytes_r1'.
@ This 16-bit value is then shifted left by 8 bits, and the subsequent 8-bit byte
@ from the buffer is ORed into the lower 8 bits to form the 24-bit result.
@ Input:
@   r0: Pointer to the command buffer. Advanced by 3 bytes after the operation.
@ Output:
@   r1: The retrieved and processed 24-bit argument (in the lower 24 bits of r1).
@======================================================================
.global arg_retrieve_24bits
.thumb_func
arg_retrieve_24bits:
    push {r2-r7, lr}

    ldrh r1, [r0], #2
    bl   swap_low2bytes_r1
    lsl  r1, r1, #8
    mov  r4, r1

    ldrb r1, [r0], #1
    orr  r1, r1, r4
    pop {r2-r7, pc}

@======================================================================
@ arg_retrieve_half: Retrieves a 16-bit half-word argument from the command buffer.
@ This function reads a 16-bit half-word from the memory location pointed to
@ by r0 (command buffer). It then calls 'swap_low2bytes_r1' to perform
@ byte swapping on the retrieved value, which is useful for correcting
@ endianness if the source data has a different byte order.
@ Input:
@   r0: Pointer to the command buffer. Advanced by 2 bytes after the operation.
@ Output:
@   r1: The retrieved and byte-swapped 16-bit argument.
@======================================================================
.global arg_retrieve_half
.thumb_func
arg_retrieve_half:
	push {r2-r7, lr}

	ldrh  r1, [r0], #2
    bl    swap_low2bytes_r1

	pop {r2-r7, pc}

@======================================================================
@ post_msg_and_return: Posts a MoT message to the console and returns.
@ This utility function facilitates sending a pre-formatted message structure
@ (pointed to by r0) to the console output queue.
@ It loads the address of the 'consoleMsgs' queue into r1 and then calls
@ 'MoT_msgPost' to perform the posting operation.
@ It then executes 'pop {r7, pc}', implying that the calling function
@ (or a function higher in the call stack that this is tailing)
@ is expected to have saved r7 (frame pointer) and lr (link register)
@ on the stack.
@ Input:
@   r0: Pointer to the MoT message link structure to be posted.
@======================================================================
.global post_msg_and_return
.thumb_func
post_msg_and_return:
	MOV_imm32 r1, consoleMsgs
    bl  MoT_msgPost
    pop {r7, pc}

@======================================================================
@ delay: Provides a software-based delay.
@ This function implements a simple delay using nested loops. The duration
@ of the delay is proportional to the value passed in r0 (outer loop count)
@ and the fixed inner loop count (16000).
@ Input:
@   r0: Outer loop count. A larger value results in a longer delay.
@======================================================================
    .global delay
    .thumb_func
delay:
    push {r1-r3, lr}
    cmp r0, #0
    beq end
loop:
    movs r2, #16000
dec:
    subs r2, r2, #1
    bne dec
    subs r0, r0, #1
    bne loop
end:
    pop {r1-r3, pc}

@======================================================================
@ freq_to_arr_ticks: Converts frequency (Hz) to timer Auto-Reload (ARR) ticks.
@ Given an input frequency in Hertz (Hz) in r0, this function calculates the
@ corresponding ARR value needed to achieve this frequency with a timer clock
@ of 1,000,000 Hz (TARGET_TIM_CLOCK_HZ). The formula used is:
@ ARR = (TARGET_TIM_CLOCK_HZ / input_frequency_hz) - 1.
@ It includes error handling for input frequency being 0 or too high
@ (which would result in an ARR value less than 0), in which case it returns 0.
@ Input:
@   r0: Frequency in Hertz.
@ Output:
@   r0: Calculated ARR value in timer ticks, or 0 on error.
@======================================================================
.global freq_to_arr_ticks
.thumb_func
freq_to_arr_ticks:
    push {lr}
    mov r1, r0
    cmp r1, #0
    beq err
    ldr r0, =1000000
    cmp r0, r1
    blt err
    bl __aeabi_uidiv
    subs r0, r0, #1
    b done
err:
    movs r0, #0
done:
    pop {pc}

@======================================================================
@ pull_up_down: Converts an analog input value to a binary-like output (0 or 4095).
@ This function takes an input value in r0 (presumably an ADC reading)
@ and compares it against a fixed threshold of 2040.
@ - If the input value is less than 2040, r0 is set to 0.
@ - If the input value is greater than or equal to 2040, r0 is set to 4095.
@ This effectively creates a digital high/low output based on the analog input,
@ possibly for simple threshold detection or mapping to DAC output limits.
@ Input:
@   r0: The analog input value (e.g., 12-bit ADC result).
@ Output:
@   r0: Modified to either 0 or 4095.
@======================================================================
.global pull_up_down
.thumb_func
pull_up_down:
	push {r1, lr}
	cmp r0, #2040
	blt down
	b up

down:
	mov r0, #0
	b done_pp
up:
	mov r0, #4095
	b done_pp

done_pp:
	pop {r1, pc}
