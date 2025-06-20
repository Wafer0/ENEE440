#define __ASSEMBLY__
#include "macros_and_definitions.S"

.syntax unified
.thumb

.text
@======================================================================
@ w25q128_read_jedec_id: Reads JEDEC ID from W25Q128 flash memory.
@ This function sends the JEDEC ID command (0x9F) to the flash chip.
@ It then reads three bytes: Manufacturer ID, Device Type ID, and Capacity ID,
@ by sending dummy bytes for each. These three ID bytes are stored into the
@ dedicated global variables: 'w25q128_manufacturer_id',
@ 'w25q128_device_type_id', and 'w25q128_capacity_id' respectively.
@ The function handles asserting and de-asserting Chip Select (CS).
@======================================================================
.global w25q128_read_jedec_id
.thumb_func
w25q128_read_jedec_id:
    push {r0-r7, lr}

    bl w25q128_assert_cs
    movs r0, #W25_CMD_JEDEC_ID
    bl spi_send_receive_byte

    movs r0, #W25_DUMMY_BYTE
    bl spi_send_receive_byte
    mov r4, r0

    movs r0, #W25_DUMMY_BYTE
    bl spi_send_receive_byte
    mov r5, r0

    movs r0, #W25_DUMMY_BYTE
    bl spi_send_receive_byte
    mov r6, r0

    bl w25q128_deassert_cs

    ldr r1, =w25q128_manufacturer_id
    strb r4, [r1]
    ldr r1, =w25q128_device_type_id
    strb r5, [r1]
    ldr r1, =w25q128_capacity_id
    strb r6, [r1]

	pop {r0-r7, pc}
	
@======================================================================
@ print_ident: Formats the JEDEC ID bytes into a message string.
@ This function retrieves the Manufacturer ID, Device Type ID, and Capacity ID
@ from their respective global variables ('w25q128_manufacturer_id', etc.).
@ It then converts each byte into a two-character hexadecimal ASCII representation
@ by processing its upper and lower nibbles using the 'nibble_to_ascii' helper.
@ These ASCII characters are written directly into the 'device8_read_identtxt'
@ message string buffer at predefined offsets, replacing placeholders.
@ For example, it populates the "XX" in "MF=0xXX", "Type=0xYY", "Cap=0xZZ".
@======================================================================
.global print_ident
.thumb_func
print_ident:
    push {r0-r7, lr}

    ldr r1, =device8_read_identtxt

    ldr r2, =w25q128_manufacturer_id
    ldrb r4, [r2]

    mov r5, r4
    lsr r5, r5, #4
    bl nibble_to_ascii
    strb r0, [r1, #20]

    mov r5, r4
    and r5, r5, #0x0F
    bl nibble_to_ascii
    strb r0, [r1, #21]

    ldr r2, =w25q128_device_type_id
    ldrb r4, [r2]

    mov r5, r4
    lsr r5, r5, #4
    bl nibble_to_ascii
    strb r0, [r1, #31]

    mov r5, r4
    and r5, r5, #0x0F
    bl nibble_to_ascii
    strb r0, [r1, #32]

    ldr r2, =w25q128_capacity_id
    ldrb r4, [r2]

    mov r5, r4
    lsr r5, r5, #4
    bl nibble_to_ascii
    strb r0, [r1, #41]

    mov r5, r4
    and r5, r5, #0x0F
    bl nibble_to_ascii
    strb r0, [r1, #42]

	pop {r0-r7, pc}
