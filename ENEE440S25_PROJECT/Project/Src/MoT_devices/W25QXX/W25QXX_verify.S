#define __ASSEMBLY__
#include "macros_and_definitions.S"

.syntax unified
.thumb

.text

@======================================================================
@ w25q128_verify_ram_buffer: Compares two RAM buffers byte by byte.
@ This function takes the starting addresses of two RAM buffers and compares
@ their contents for a total of RAM_BUFFER_SIZE bytes. It is used
@ to verify data integrity, for example, by comparing an original data buffer
@ with data that has been written to and then read back from flash memory.
@ Inputs:
@   r0: Starting address of the first RAM buffer (e.g., original data).
@   r1: Starting address of the second RAM buffer (e.g., data read from flash).
@ Outputs:
@   r0: Returns 1 if all bytes in both buffers are identical (verification success).
@       Returns 0 if any byte mismatch is found (verification failure).
@======================================================================
.global w25q128_verify_ram_buffer
.thumb_func
w25q128_verify_ram_buffer:
    push {r1-r5, lr}

    mov r2, r0
    mov r3, r1
    ldr r4, =RAM_BUFFER_SIZE

verify_loop_start:
    cmp r4, #0
    beq verify_success

    ldrb r0, [r2], #1
    ldrb r1, [r3], #1

    cmp r0, r1
    bne verify_failure

    subs r4, r4, #1
    b verify_loop_start

verify_success:
    movs r0, #1
    b verify_end

verify_failure:
    movs r0, #0

verify_end:
    pop {r1-r5, pc}
