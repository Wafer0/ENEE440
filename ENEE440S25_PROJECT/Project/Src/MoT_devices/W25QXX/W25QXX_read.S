#define __ASSEMBLY__
#include "macros_and_definitions.S"

.syntax unified
.thumb

.text
@======================================================================
@ w25q128_read_ram_buffer: Reads a block of data from W25Q128 flash into RAM.
@ This function reads a number of bytes equal to RAM_BUFFER_SIZE from the
@ W25Q128 flash memory, starting at the specified flash address, and stores
@ the data into the provided RAM buffer.
@ The process involves:
@ 1. Asserting Chip Select (CS).
@ 2. Sending the Read Data command (e.g., 0x03) to the flash memory.
@ 3. Sending the 24-bit starting flash address from which to read.
@ 4. Repeatedly sending dummy bytes via SPI to clock in data from the flash,
@    storing each received byte into the destination RAM buffer. This is done
@    RAM_BUFFER_SIZE times.
@ 5. De-asserting Chip Select (CS) once all data has been read.
@ Inputs:
@   r0: Starting 24-bit address in flash memory to read from.
@   r1: Starting address of the destination RAM buffer.
@======================================================================
.global w25q128_read_ram_buffer
.thumb_func
w25q128_read_ram_buffer:
    push {r2-r5, lr}

    bl w25q128_assert_cs

    movs r2, #W25_CMD_READ_DATA
    push {r0, r1}
    mov r0, r2
    bl spi_send_receive_byte
    pop {r0, r1}

    mov r3, r0
    lsr r2, r3, #16
    mov r0, r2
    bl spi_send_receive_byte

    lsr r2, r3, #8
    mov r0, r2
    bl spi_send_receive_byte

    mov r0, r3
    bl spi_send_receive_byte

    ldr r4, =RAM_BUFFER_SIZE
    mov r5, r1

read_byte_loop_start:
    cmp r4, #0
    beq read_byte_loop_end

    movs r0, #W25_DUMMY_BYTE
    bl spi_send_receive_byte

    strb r0, [r5], #1

    subs r4, r4, #1
    b read_byte_loop_start

read_byte_loop_end:
    bl w25q128_deassert_cs

    pop {r2-r5, pc}
