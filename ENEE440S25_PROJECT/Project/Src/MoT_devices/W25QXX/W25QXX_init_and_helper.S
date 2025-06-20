#define __ASSEMBLY__
#include "macros_and_definitions.S"

.syntax unified
.thumb

.text
@======================================================================
@ w25q128_assert_cs: Asserts the Chip Select (CS) line for W25Q128 flash.
@ This helper function drives the GPIO pin configured as Chip Select (NSS),
@ PB12, to a LOW logic level. Asserting CS is necessary to
@ begin communication with the W25Q128 flash memory chip.
@======================================================================
.global w25q128_assert_cs
.thumb_func
w25q128_assert_cs:
    push {r0, r1}
    MOV_imm32 r1, GPIOB_BASE
    movs r0, #(1 << (PIN12 + 16))
    str r0, [r1, #GPIOx_BSRR]
    pop {r0, r1}
    bx lr

@======================================================================
@ w25q128_deassert_cs: De-asserts the Chip Select (CS) line for W25Q128 flash.
@ This helper function drives the GPIO pin configured as Chip Select (NSS),
@ PB12, to a HIGH logic level. De-asserting CS finalizes
@ a command sequence or deselects the flash memory chip.
@======================================================================
.global w25q128_deassert_cs
.thumb_func
w25q128_deassert_cs:
    push {r0, r1}
    MOV_imm32 r1, GPIOB_BASE
    movs r0, #(1 << PIN12)
    str r0, [r1, #GPIOx_BSRR]
    pop {r0, r1}
    bx lr

@======================================================================
@ spi_send_receive_byte: Sends one byte and receives one byte via SPI2.
@ This function handles a single byte, full-duplex SPI transaction.
@ It waits for the Transmit Buffer Empty (TXE) flag before sending the byte
@ provided in r0. After transmission, it waits for the Receive Buffer Not Empty
@ (RXNE) flag and then reads the received byte into r0.
@ Input:
@   r0: The 8-bit byte to be sent over SPI.
@ Output:
@   r0: The 8-bit byte received from SPI (from the slave device).
@======================================================================
.global spi_send_receive_byte
.thumb_func
spi_send_receive_byte:
    push {lr}
    push {r1-r3}

    MOV_imm32 r1, SPI2_BASE

spi_wait_txe:
    ldr r2, [r1, #SPIx_SR]
    tst r2, #SPI_SR_TXE
    beq spi_wait_txe
    mov r3, r0
    strb r3, [r1, #SPIx_DR]

spi_wait_rxne:
    ldr r2, [r1, #SPIx_SR]
    tst r2, #SPI_SR_RXNE
    beq spi_wait_rxne
    ldrb r0, [r1, #SPIx_DR]

    pop {r1-r3}
    pop {pc}

@======================================================================
@ short_delay: Provides a simple software delay loop.
@ The duration of the delay is determined by the initial value in r0.
@ The loop decrements r0 until it becomes zero.
@ Input:
@   r0: Loop count for the delay. A larger value results in a longer delay.
@======================================================================
.global short_delay
.thumb_func
short_delay:
    push {r0, lr}
delay_loop_internal:
    subs r0, r0, #1
    bne delay_loop_internal
    pop {r0, pc}

@======================================================================
@ w25q128_reset_init: Initializes SPI2 and performs a software reset on W25Q128.
@ This function ensures the SPI2 peripheral is configured for communication
@ with the W25Q128 flash memory and then executes the software reset
@ sequence for the flash chip.
@ Steps:
@ 1. Calls SPI initialization helper functions ('device7_enable_clocks',
@    'device7_configure_gpios', 'device7_configure_spi_peripheral') to set up SPI2.
@ 2. Sends the "Enable Reset" command (0x66) to the W25Q128.
@ 3. Introduces a short delay.
@ 4. Sends the "Reset Device" command (0x99) to the W25Q128.
@ 5. Waits for the reset recovery time (t_RST) using 'short_delay'.
@ This sequence brings the flash memory to a known, default state.
@======================================================================
.global w25q128_reset_init
.thumb_func
w25q128_reset_init:
    push {r0-r3, lr}

    bl device7_enable_clocks
    bl device7_configure_gpios
    bl device7_configure_spi_peripheral

    bl w25q128_assert_cs
    movs r0, #W25_CMD_ENABLE_RESET
    bl spi_send_receive_byte
    bl w25q128_deassert_cs

    movs r0, #10
    bl short_delay

    bl w25q128_assert_cs
    movs r0, #W25_CMD_RESET_DEVICE
    bl spi_send_receive_byte
    bl w25q128_deassert_cs

    MOV_imm32 r0, 500
    bl short_delay
    pop {r0-r3, pc}
