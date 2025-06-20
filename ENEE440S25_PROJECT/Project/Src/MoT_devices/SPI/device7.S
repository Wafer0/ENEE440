#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

.syntax unified
.thumb
.text

.equ MAX_ARR_SIZE, 10
@======================================================================
@ device7_cmdHandler: Command dispatcher for Device 7 (SPI Loopback Test).
@ It reads a command ID byte from the MoT message payload (r0), masks it
@ with 0x03 (to support commands 0-3), and then uses a table branch (TBB)
@ to jump to the appropriate command handling routine listed in 'device7_cmds'.
@ r0: Pointer to MoT command payload; first byte is command ID.
@ r1: Used to store and manipulate the command ID.
@======================================================================
.global device7_cmdHandler
.thumb_func
device7_cmdHandler:
    push   {r7, lr}
    ldrb   r1, [r0], #1
    and    r1, r1, #0x03
    tbb    [pc, r1]
device7_cmds:
    .byte  (device7_initialize      - device7_cmds)/2
    .byte  (device7_write           - device7_cmds)/2
    .byte  (device7_read            - device7_cmds)/2
    .byte  (device7_clr_read_arr    - device7_cmds)/2
    .align 1

MoT_core_m device7, device7_cmdHandler, device7_skiptask

.section .data
.align 2

.balign 4

read_arr:
    .space MAX_ARR_SIZE
write_arr:
	.space MAX_ARR_SIZE

pointer_read:
	.byte 0
pointer_write:
	.byte 0

MoT_msgLink_m device7_init_msg, device7_init_txt, device7_init_msg_len
device7_init_txt: .asciz "device7: SPI2 initialized (PB12-15)\n\r"
.equ device7_init_msg_len, (. - device7_init_txt - 1)

MoT_msgLink_m device7_write_msg, device7_write_txt, device7_write_msg_len
device7_write_txt: .asciz "device7: SPI2 write complete\n\r"
.equ device7_write_msg_len, (. - device7_write_txt - 1)

MoT_msgLink_m device7_read_msg, device7_read_txt, device7_read_msg_len
device7_read_txt: .asciz "device7: 0x00000000000000000000\n\r"
.equ device7_read_msg_len, (. - device7_read_txt - 1)

MoT_msgLink_m device7_arr_msg, device7_arr_txt, device7_arr_msg_len
device7_arr_txt: .asciz "device7: Read and Write Buffers CLEAR\n\r"
.equ device7_arr_msg_len, (. - device7_arr_txt - 1)

.text
@======================================================================
@ device7_initialize: Initializes SPI2 for loopback testing. (Command 0x00)
@ This function orchestrates the full initialization of the SPI2 peripheral
@ and its associated GPIO pins (PB12-PB15) for Device 7. It calls helper
@ functions to:
@ 1. Enable clocks for SPI2 and GPIOB ('device7_enable_clocks'). [
@ 2. Configure GPIOB pins PB12-15 for their SPI roles (NSS, SCK, MISO, MOSI)
@    ('device7_configure_gpios').
@ 3. Configure the SPI2 peripheral parameters (master mode, baud rate, data size, etc.)
@    ('device7_configure_spi_peripheral').
@ After successful setup, it posts "device7: SPI2 initialized (PB12-15)"
@ to the console.
@======================================================================
.global device7_initialize
.thumb_func
device7_initialize:
	bl device7_enable_clocks
    bl device7_configure_gpios
    bl device7_configure_spi_peripheral

    add   r0, rDEVP, #device7_init_msg_OFFSET
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}

@======================================================================
@ device7_write: Writes data via SPI2 and captures loopback data. (Command 0x01)
@ Reads a count byte from the command payload (r0) indicating how many
@ data bytes follow.
@ Calls 'store_message_bytes_into_write_arr' to copy these data bytes from the
@ command payload into the internal 'write_arr' buffer.
@ It then loops 'count' times, calling 'device7_write_byte_action' in each
@ iteration to send one byte from 'write_arr' via SPI2 and simultaneously
@ capture the looped-back byte into 'read_arr'.
@ After all bytes are processed, it posts "device7: SPI2 write complete"
@ to the console.
@ r0: Input, pointer to command payload (count byte followed by data bytes).
@ r1: Used to hold the count of bytes to write.
@======================================================================
.global device7_write
.thumb_func
device7_write:
	ldrb r1, [r0], #1
	bl store_message_bytes_into_write_arr
write:
	bl device7_write_byte_action
	sub r1, r1, #1
	cmp r1, #0
	bne write

    add   r0, rDEVP, #device7_write_msg_OFFSET
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}

@======================================================================
@ device7_read: Reads and reports data from the internal SPI loopback buffer. (Command 0x02)
@ This function calls 'device7_read_byte_action', which formats the content
@ of the internal 'read_arr' (containing data previously captured during
@ SPI write/loopback operations) into a hexadecimal string within the
@ 'device7_read_txt' message buffer.
@ It then posts this formatted message, displaying the captured data
@ (up to 10 bytes) to the console.
@======================================================================
.global device7_read
.thumb_func
device7_read:
	bl device7_read_byte_action

    add   r0, rDEVP, #device7_read_msg_OFFSET
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}

@======================================================================
@ device7_clr_read_arr: Clears internal SPI software buffers. (Command 0x03)
@ This function calls the 'arr_clear' helper routine. 'arr_clear'
@ resets the 'pointer_read' and 'pointer_write' indices to zero and fills
@ both the 'read_arr' and 'write_arr' software buffers with zeros.
@ After clearing the buffers, it posts "device7: Read and Write Buffers CLEAR"
@ to the console as confirmation.
@======================================================================
.global device7_clr_read_arr
.thumb_func
device7_clr_read_arr:
	bl arr_clear

    add   r0, rDEVP, #device7_arr_msg_OFFSET
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}

@======================================================================
@ device7_skiptask: A minimal MoT task for Device 7.
@ As Device 7 operations serves as the default idle behavior. It passes execution
@ control to the next scheduled MoT task in the system by loading the
@ next task's context (rDEVP) and jumping to its execution address.
@======================================================================
.global device7_skiptask
.thumb_func
device7_skiptask:
    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

@======================================================================
@ device7_enable_clocks: Enables necessary peripheral clocks for SPI2 communication.
@ This helper function performs the following clock initializations:
@ 1. Enables the clock for GPIOB via the RCC_AHB2ENR register, required for
@    SPI2 pins (PB12-PB15).
@ 2. Enables the clock for the SPI2 peripheral itself via the RCC_APB1ENR1
@    register.
@ 3. Optionally, it resets the SPI2 peripheral using RCC_APB1RSTR1 to ensure
@    it starts in a known state.
@ Data Synchronization Barriers (dsb) are used to ensure clock changes take effect.
@======================================================================
.global device7_enable_clocks
.thumb_func
device7_enable_clocks:
    push {r0-r2, lr}
    MOV_imm32 r0, RCC_BASE
    ldr r1, [r0, #RCC_AHB2ENR]
    orr r1, r1, #RCC_AHB2ENR_GPIOBEN
    str r1, [r0, #RCC_AHB2ENR]
    dsb
    ldr r1, [r0, #RCC_APB1ENR1]
    orr r1, r1, #RCC_APB1ENR1_SPI2EN
    str r1, [r0, #RCC_APB1ENR1]
    dsb

    ldr r1, [r0, #RCC_APB1RSTR1]
    orr r1, r1, #RCC_APB1RSTR1_SPI2RST
    str r1, [r0, #RCC_APB1RSTR1]
    dsb
    bic r1, r1, #RCC_APB1RSTR1_SPI2RST
    str r1, [r0, #RCC_APB1RSTR1]
    dsb

    pop {r0-r2, pc}

@======================================================================
@ device7_configure_gpios: Configures GPIOB pins for SPI2 functionality.
@ Sets up GPIOB pins PB12, PB13, PB14, and PB15 for SPI2:
@ - PB12 (NSS): Configured as GPIO Output, Push-Pull, Very High Speed,
@   No Pull-up/down. Initialized to HIGH (de-asserted).
@ - PB13 (SCK): Configured for Alternate Function AF5 (SPI2_SCK).
@ - PB14 (MISO): Configured for Alternate Function AF5 (SPI2_MISO).
@ - PB15 (MOSI): Configured for Alternate Function AF5 (SPI2_MOSI).
@ All AF pins are set to Push-Pull, Very High Speed, No Pull-up/down.
@======================================================================
.global device7_configure_gpios
.thumb_func
device7_configure_gpios:
    push {r0-r3, lr}
    MOV_imm32 r0, GPIOB_BASE

    ldr r1, [r0, #GPIOx_MODER]
    bic  r1, r1, #(0b11 << (PIN12*2))
    orr  r1, r1, #(GPIO_MODER_OUTPUT << (PIN12*2))
    str  r1, [r0, #GPIOx_MODER]

    ldr r1, [r0, #GPIOx_OTYPER]
    bic r1, r1, #(1 << PIN12)
    str r1, [r0, #GPIOx_OTYPER]

    ldr r1, [r0, #GPIOx_OSPEEDR]
    orr r1, r1, #(GPIO_OSPEEDR_VHIGH << (PIN12*2))
    str r1, [r0, #GPIOx_OSPEEDR]

    ldr r1, [r0, #GPIOx_PUPDR]
    bic r1, r1, #(0b11 << (PIN12*2))
    str r1, [r0, #GPIOx_PUPDR]

    movs r1, #(1 << PIN12)
    str r1, [r0, #GPIOx_BSRR]

    ldr r1, [r0, #GPIOx_MODER]
    bic r1, r1, #(0b11 << (PIN13*2))
    orr r1, r1, #(GPIO_MODER_AF << (PIN13*2))
    bic r1, r1, #(0b11 << (PIN14*2))
    orr r1, r1, #(GPIO_MODER_AF << (PIN14*2))
    bic r1, r1, #(0b11 << (PIN15*2))
    orr r1, r1, #(GPIO_MODER_AF << (PIN15*2))
    str r1, [r0, #GPIOx_MODER]

    ldr r1, [r0, #GPIOx_OTYPER]
    movs r2, #((1 << PIN13) | (1 << PIN14) | (1 << PIN15))
    bic r1, r1, r2
    str r1, [r0, #GPIOx_OTYPER]

    ldr r1, [r0, #GPIOx_OSPEEDR]
    movs r2, #0
    orr r2, r2, #(GPIO_OSPEEDR_VHIGH << (PIN13*2))
    orr r2, r2, #(GPIO_OSPEEDR_VHIGH << (PIN14*2))
    orr r2, r2, #(GPIO_OSPEEDR_VHIGH << (PIN15*2))
    orr r1, r1, r2
    str r1, [r0, #GPIOx_OSPEEDR]

    ldr r1, [r0, #GPIOx_PUPDR]
    movs r2, #0
    orr r2, r2, #(0b11 << (PIN13*2))
    orr r2, r2, #(0b11 << (PIN14*2))
    orr r2, r2, #(0b11 << (PIN15*2))
    bic r1, r1, r2
    str r1, [r0, #GPIOx_PUPDR]

    ldr r1, [r0, #GPIOx_AFRH]

    movs r3, #0
    orr  r3, r3, #(AF5 << ((PIN13-8)*4))
    orr  r3, r3, #(AF5 << ((PIN14-8)*4))
    orr  r3, r3, #(AF5 << ((PIN15-8)*4))

    movs r2, #0
    orr  r2, r2, #(0xF << ((PIN13-8)*4))
    orr  r2, r2, #(0xF << ((PIN14-8)*4))
    orr  r2, r2, #(0xF << ((PIN15-8)*4))

    bic r1, r1, r2
    orr r1, r1, r3
    str r1, [r0, #GPIOx_AFRH]

    pop {r0-r3, pc}

@======================================================================
@ device7_configure_spi_peripheral: Configures the SPI2 peripheral settings.
@ This helper function sets up SPI2 for master mode operation:
@ 1. Disables SPI2 (clears SPE bit in SPI_CR1) before configuration.
@ 2. Configures SPI_CR1: Master mode (MSTR=1), Baud rate PCLK/16 (BR bits),
@    CPOL=0, CPHA=0 (SPI Mode 0), Software Slave Management enabled (SSM=1),
@    Internal Slave Select set high (SSI=1).
@ 3. Configures SPI_CR2: 8-bit data size (DS bits), RXNE event generated on
@    8-bit reception (FRXTH=1).
@ 4. Enables SPI2 (sets SPE bit in SPI_CR1).
@======================================================================
.global device7_configure_spi_peripheral
.thumb_func
device7_configure_spi_peripheral:
    push {r0-r2, lr}
    MOV_imm32 r0, SPI2_BASE

    ldr r1, [r0, #SPIx_CR1]
    bic r1, r1, #SPI_CR1_SPE
    str r1, [r0, #SPIx_CR1]

    movs r1, #0
    orr r1, r1, #SPI_CR1_MSTR
    orr r1, r1, #SPI_CR1_BR_DIV16
    orr r1, r1, #SPI_CR1_SSM
    orr r1, r1, #SPI_CR1_SSI
    str r1, [r0, #SPIx_CR1]

    movs r2, #0
    orr r2, r2, #SPI_CR2_DS_8BIT
    orr r2, r2, #SPI_CR2_FRXTH
    str r2, [r0, #SPIx_CR2]

    ldr r1, [r0, #SPIx_CR1]
    orr r1, r1, #SPI_CR1_SPE
    str r1, [r0, #SPIx_CR1]

    pop {r0-r2, pc}

@======================================================================
@ device7_write_byte_action: Performs a single SPI byte write and loopback read.
@ This helper function orchestrates the transmission of one byte via SPI2
@ and the reception of the byte looped back.
@ 1. Calls 'read_byte_from_write_arr' to get the next byte to send (result in r0).
@ 2. Asserts NSS (PB12 set LOW).
@ 3. Waits for the SPI Transmit Buffer Empty (TXE) flag.
@ 4. Writes the byte to the SPI Data Register (DR) for transmission.
@ 5. Waits for the SPI Receive Buffer Not Empty (RXNE) flag.
@ 6. Reads the received (looped-back) byte from the SPI DR.
@ 7. Calls 'write_byte_to_read_arr' to store the received byte into 'read_arr'.
@ 8. Waits for the SPI Busy (BSY) flag to clear.
@ 9. De-asserts NSS (PB12 set HIGH).
@======================================================================
.global device7_write_byte_action
.thumb_func
device7_write_byte_action:
    push {r0-r7, lr}
	bl read_byte_from_write_arr
    mov r1, r0

    MOV_imm32 r4, SPI2_BASE
    MOV_imm32 r6, GPIOB_BASE

    movs r3, #(1 << (PIN12 + 16))
    str r3, [r6, #GPIOx_BSRR]

_wait_txe_write_byte:
    ldr r7, [r4, #SPIx_SR]
    tst r7, #SPI_SR_TXE
    beq _wait_txe_write_byte
    strb r1, [r4, #SPIx_DR]

_wait_rxne_write_byte:
    ldr r7, [r4, #SPIx_SR]
    tst r7, #SPI_SR_RXNE
    beq _wait_rxne_write_byte
    ldrb r2, [r4, #SPIx_DR]

	mov r0, r2
	bl write_byte_to_read_arr

_wait_bsy_write_byte:
    ldr r7, [r4, #SPIx_SR]
    tst r7, #SPI_SR_BSY
    bne _wait_bsy_write_byte
    movs r3, #(1 << PIN12)
    str r3, [r6, #GPIOx_BSRR]

    pop {r0-r7, pc}

@======================================================================
@ device7_read_byte_action: Formats data from 'read_arr' into a message string.
@ This function iterates through the 'read_arr' buffer (up to MAX_ARR_SIZE bytes).
@ For each byte in 'read_arr', it converts the byte into two ASCII hexadecimal
@ characters using the 'nibble_to_ascii' helper. These ASCII characters are then
@ written into the 'device7_read_txt' message string, replacing the
@ placeholder 0s. This prepares the message for console output.
@======================================================================
.global device7_read_byte_action
.thumb_func
device7_read_byte_action:
    push {r1-r5, lr}

    ldr r1, =read_arr
    ldr r2, =device7_read_txt
    add r2, r2, #11
    mov r3, #0

device7_loop:
    cmp r3, #MAX_ARR_SIZE
    bge device7_done

    ldrb r4, [r1], #1

    mov r5, r4
    lsr r5, r5, #4
    bl nibble_to_ascii
    strb r0, [r2], #1

    mov r5, r4
    and r5, r5, #0x0F
    bl nibble_to_ascii
    strb r0, [r2], #1

    add r3, r3, #1
    b device7_loop

device7_done:
    pop {r1-r5, pc}

@======================================================================
@ arr_clear: Clears the SPI software read and write buffers and their pointers.
@ This helper function performs the following actions:
@ 1. Resets 'pointer_read' (index for 'read_arr') to 0.
@ 2. Resets 'pointer_write' (index for 'write_arr') to 0.
@ 3. Fills the 'read_arr' buffer with zeros for MAX_ARR_SIZE bytes.
@ 4. Fills the 'write_arr' buffer with zeros for MAX_ARR_SIZE bytes.
@ This ensures a clean state for subsequent SPI operations.
@======================================================================
.global arr_clear
.thumb_func
arr_clear:
    push {r0-r3, lr}

	ldr r0, =pointer_read
	mov r1, #0
	strb r1, [r0]
	ldr r0, =pointer_write
	strb r1, [r0]

    ldr r0, =read_arr
    mov r1, #MAX_ARR_SIZE
    mov r2, #0
clear_read_loop:
    cmp r1, #0
    beq done_clear_read
    strb r2, [r0], #1
    subs r1, r1, #1
    b clear_read_loop
done_clear_read:

    ldr r0, =write_arr
    mov r1, #MAX_ARR_SIZE
    mov r2, #0
clear_write_loop:
    cmp r1, #0
    beq done_clear_write
    strb r2, [r0], #1
    subs r1, r1, #1
    b clear_write_loop
done_clear_write:

    pop {r0-r3, pc}

@======================================================================
@ write_byte_to_read_arr: Writes a byte to the 'read_arr' buffer.
@ Takes a byte in r0 and writes it to the 'read_arr' at the current
@ position indicated by 'pointer_read'. It then increments 'pointer_read'.
@ This is used to store bytes received from SPI loopback.
@ r0: Input, the byte to be written to 'read_arr'.
@======================================================================
.global write_byte_to_read_arr
.thumb_func
write_byte_to_read_arr:
    push {r1-r3, lr}

    ldr  r1, =pointer_read
    ldrb r3, [r1]
    ldr r2, =read_arr
    add r2, r2, r3

    strb r0, [r2]

    add r3, r3, #1
    strb r3, [r1]

    pop {r1-r3, pc}

@======================================================================
@ read_byte_from_write_arr: Reads a byte from the 'write_arr' buffer.
@ Reads a byte from 'write_arr' at the current position indicated by
@ 'pointer_write' and returns it in r0. It then increments 'pointer_write'.
@ This is used to fetch the next byte to be transmitted via SPI.
@ r0: Output, the byte read from 'write_arr'.
@======================================================================
.global read_byte_from_write_arr
.thumb_func
read_byte_from_write_arr:
    push {r1-r3, lr}

    ldr  r1, =pointer_write
    ldrb r3, [r1]
    ldr r2, =write_arr
    add r2, r2, r3

    ldrb r0, [r2]

    add r3, r3, #1
    strb r3, [r1]

    pop {r1-r3, pc}

@======================================================================
@ store_message_bytes_into_write_arr: Copies bytes from command payload to 'write_arr'.
@ This function takes a pointer to the command payload in r0 and a byte
@ count in r1. It copies 'r1' bytes from the source (command payload)
@ to the 'write_arr' buffer. Both source (r0) and destination ('write_arr'
@ internal pointer) are advanced during the copy.
@ r0: Input, pointer to the source data (command payload). Will be updated.
@ r1: Input, the number of bytes to copy. Will be decremented to 0.
@======================================================================
.global store_message_bytes_into_write_arr
.thumb_func
store_message_bytes_into_write_arr:
    push {r0-r4, lr}

    ldr r2, =write_arr
loop_storing_message:
    cmp r1, #0
    beq done_storing_message

    ldrb r3, [r0], #1
    strb r3, [r2], #1

    subs r1, r1, #1
    b loop_storing_message

done_storing_message:
    pop {r0-r4, pc}
