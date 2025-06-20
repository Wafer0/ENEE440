#define __ASSEMBLY__
#include "macros_and_definitions.S"

.syntax unified
.thumb

.text

@======================================================================
@ w25q128_erase_sector: Erases a 4KB sector in the W25Q128 flash memory.
@ This function sends the Sector Erase command (0x20) to the flash chip
@ for the specified 24-bit sector address. It handles enabling write
@ operations, sending the command and address, and waiting for the
@ erase operation to complete by polling the BUSY bit in Status Register-1.
@ Inputs:
@   r0: Starting 24-bit address of the sector to erase. Must be sector-aligned.
@======================================================================
.global w25q128_erase_sector
.thumb_func
w25q128_erase_sector:
    push {r0-r3, lr}

    bl w25q128_write_enable

    bl w25q128_assert_cs

    movs r1, #W25_CMD_SECTOR_ERASE
    push {r0}
    mov r0, r1
    bl spi_send_receive_byte
    pop {r0}

    mov r2, r0
    lsr r1, r2, #16
    mov r0, r1
    bl spi_send_receive_byte

    lsr r1, r2, #8
    mov r0, r1
    bl spi_send_receive_byte

    mov r0, r2
    bl spi_send_receive_byte

    bl w25q128_deassert_cs

    bl w25q128_wait_for_write_complete

    pop {r0-r3, pc}

@======================================================================
@ w25q128_write_ram_buffer: Writes data from a RAM buffer to W25Q128 flash.
@ This function writes a total of RAM_BUFFER_SIZE bytes from the specified
@ RAM buffer to the flash memory, starting at the given flash address.
@ The write operation is performed page by page (PAGE_SIZE bytes per page).
@ For each page, it enables write operations, sends the Page Program command
@ (0x02), the 24-bit flash address for that page, and then the page data.
@ It waits for each page program operation to complete before proceeding
@ to the next page.
@ PRECONDITION: The target flash sector(s) must be erased prior to writing.
@ Inputs:
@   r0: Starting address of the source RAM buffer.
@   r1: Starting 24-bit address in flash memory where data will be written.
@======================================================================
.global w25q128_write_ram_buffer
.thumb_func
w25q128_write_ram_buffer:
    push {r4-r7, lr}

    ldr r2, =RAM_BUFFER_SIZE
    mov r7, r0
    mov r6, r1

write_page_loop_start:
    cmp r2, #0
    beq write_page_loop_end

    bl w25q128_write_enable

    bl w25q128_assert_cs

    movs r4, #W25_CMD_PAGE_PROGRAM
    mov r0, r4
    bl spi_send_receive_byte

    mov r5, r6

    lsr r4, r5, #16
    mov r0, r4
    bl spi_send_receive_byte

    lsr r4, r5, #8
    mov r0, r4
    bl spi_send_receive_byte

    mov r0, r5
    bl spi_send_receive_byte

    mov r3, #PAGE_SIZE
send_data_byte_loop_start:
    cmp r3, #0
    beq send_data_byte_loop_end

    ldrb r4, [r7], #1
    mov r0, r4
    bl spi_send_receive_byte

    subs r3, r3, #1
    b send_data_byte_loop_start
send_data_byte_loop_end:

    bl w25q128_deassert_cs

    bl w25q128_wait_for_write_complete

    add r6, r6, #PAGE_SIZE
    sub r2, r2, #PAGE_SIZE

    b write_page_loop_start

write_page_loop_end:
    pop {r4-r7, pc}

@======================================================================
@ w25q128_write_enable: Sends the Write Enable (WREN) command to the flash.
@ This helper function asserts Chip Select (CS), sends the WREN command (0x06)
@ via SPI, and then de-asserts CS. Setting the Write Enable Latch (WEL)
@ is a prerequisite for any erase or program (write) operation on the
@ W25Q128 flash memory.
@======================================================================
.global w25q128_write_enable
.thumb_func
w25q128_write_enable:
    push {r0, lr}
    bl w25q128_assert_cs
    movs r0, #W25_CMD_WRITE_ENABLE
    bl spi_send_receive_byte
    bl w25q128_deassert_cs
    pop {r0, pc}

@======================================================================
@ w25q128_read_status_register1: Reads Status Register-1 (SR1) of the W25Q128.
@ This helper function asserts CS, sends the Read Status Register-1 command
@ (0x05), sends a dummy byte to clock out the SR1 data, and then de-asserts CS.
@ The value of SR1 is returned in r0. SR1 contains important flags like
@ the BUSY bit (indicates if an internal operation is in progress) and the
@ WEL bit (Write Enable Latch status).
@ Outputs:
@   r0: The 8-bit value of Status Register-1.
@======================================================================
.global w25q128_read_status_register1
.thumb_func
w25q128_read_status_register1:
    push {r0, lr}
    bl w25q128_assert_cs
    movs r0, #W25_CMD_READ_STATUS_REG1
    bl spi_send_receive_byte
    movs r0, #W25_DUMMY_BYTE
    bl spi_send_receive_byte
    bl w25q128_deassert_cs
    pop {r0, pc}

@======================================================================
@ w25q128_wait_for_write_complete: Polls SR1 until BUSY bit is clear.
@ This helper function repeatedly calls 'w25q128_read_status_register1'
@ to get the current Status Register-1 value. It then checks the BUSY bit
@ (SR1_BUSY_BIT, bit 0). The loop continues as long as the BUSY
@ bit is set, indicating that an internal flash memory operation
@ (erase or program) is still in progress. Once the BUSY bit is clear,
@ the function returns.
@======================================================================
.global w25q128_wait_for_write_complete
.thumb_func
w25q128_wait_for_write_complete:
    push {r0, r1, lr}
wait_busy_loop:
    bl w25q128_read_status_register1
    movs r1, #SR1_BUSY_BIT
    tst r0, r1
    bne wait_busy_loop
    pop {r0, r1, pc}
