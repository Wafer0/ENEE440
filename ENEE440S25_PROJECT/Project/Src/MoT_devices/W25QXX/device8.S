#define __ASSEMBLY__
#include "MoTstructures.h"
#include "macros_and_definitions.S"

.syntax unified
.thumb

.section .data
.align 2

.global w25q128_manufacturer_id
.global w25q128_device_type_id
.global w25q128_capacity_id
w25q128_manufacturer_id: .byte 0
w25q128_device_type_id:  .byte 0
w25q128_capacity_id:     .byte 0
.balign 4

.global received_buffer
received_buffer:    .space RAM_BUFFER_SIZE

.global ram_buffer
ram_buffer: .space RAM_BUFFER_SIZE

.text

@======================================================================
@ device8_cmdHandler: Command dispatcher for Device 8 (W25QXX Flash).
@ It reads a command ID byte from the MoT message payload (r0), masks it
@ with 0x0F (to support commands 0-6 as defined in the table, though mask
@ allows up to 15), and then uses a table branch (TBB) to jump to the
@ appropriate command handling routine listed in 'device8_cmds'.
@ r0: Pointer to MoT command payload; first byte is command ID.
@ r1: Used to store and manipulate the command ID.
@======================================================================
.global device8_cmdHandler
.thumb_func
device8_cmdHandler:
    push   {r7, lr}
    ldrb   r1, [r0], #1
    and    r1, r1, #0x0F
    tbb    [pc, r1]
device8_cmds:
    .byte  (device8_initialize - device8_cmds)/2
    .byte  (device8_read_ident - device8_cmds)/2
    .byte  (device8_erase - device8_cmds)/2
    .byte  (device8_input - device8_cmds)/2
    .byte  (device8_copy - device8_cmds)/2
    .byte  (device8_verify - device8_cmds)/2
    .byte  (device8_output - device8_cmds)/2
    .align 1

MoT_core_m device8, device8_cmdHandler, device8_skiptask

.data
.global device8_read_identtxt
MoT_msgLink_m device8_initmsg,  device8_inittxt,  device8_initmsglen
device8_inittxt:
    .ascii "device8 has been initialized on W25Q128\n\r\0"
.equ device8_initmsglen, (. - device8_inittxt)

MoT_msgLink_m device8_read_identmsg,  device8_read_identtxt,  device8_read_identmsglen
device8_read_identtxt:
    .ascii "device8 JEDEC: MF=0x00, Type=0x00, Cap=0x00\n\r\0"
.equ device8_read_identmsglen, (. - device8_read_identtxt)

MoT_msgLink_m device8_erase_blockmsg,  device8_erase_blocktxt,  device8_erase_blockmsglen
device8_erase_blocktxt:
    .ascii "device8 erased directed block\n\r\0"
.equ device8_erase_blockmsglen, (. - device8_erase_blocktxt)

MoT_msgLink_m device8_verify_successmsg,  device8_verify_successtxt,  device8_verify_successmsglen
device8_verify_successtxt:
    .ascii "device8 verification successful\n\r\0"
.equ device8_verify_successmsglen, (. - device8_verify_successtxt)

MoT_msgLink_m device8_verify_failedmsg,  device8_verify_failedtxt,  device8_verify_failedmsglen
device8_verify_failedtxt:
    .ascii "device8 verification failed\n\r\0"
.equ device8_verify_failedmsglen, (. - device8_verify_failedtxt)

MoT_msgLink_m device8_inputmsg,  device8_inputtxt,  device8_inputmsglen
device8_inputtxt:
    .ascii "device8 input is in ram\n\r\0"
.equ device8_inputmsglen, (. - device8_inputtxt)

MoT_msgLink_m device8_copy_donemsg,  device8_copy_donetxt,  device8_copy_donemsglen
device8_copy_donetxt:
    .ascii "device8 copy complete\n\r\0"
.equ device8_copy_donemsglen, (. - device8_copy_donetxt)

MoT_msgLink_m device8_outputmsg,  device8_outputtxt,  device8_outputmsglen
device8_outputtxt:
    .ascii "device8 output from flash 0x0000000000000000000000000000000000000000000000000000000000000000\n\r\0"
.equ device8_outputmsglen, (. - device8_outputtxt)

.align 1
.text
@======================================================================
@ device8_initialize: Initializes the W25QXX Flash memory. (Command 0x00)
@ Calls 'w25q128_reset_init' to perform the hardware initialization and
@ reset sequence for the W25Q128 flash memory chip, including SPI2 setup.
@ After successful initialization, it posts the message
@ "device8 has been initialized on W25Q128" to the console.
@======================================================================
.global device8_initialize
.thumb_func
device8_initialize:
	bl w25q128_reset_init

    add   r0, rDEVP, #device8_initmsg_OFFSET
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}

@======================================================================
@ device8_read_ident: Reads and displays JEDEC ID of the W25QXX Flash. (Command 0x01)
@ 1. Calls 'w25q128_read_jedec_id' to send the JEDEC ID command (0x9F) to
@    the flash memory and retrieve the Manufacturer ID, Device Type ID,
@    and Capacity ID. These are stored in global variables.
@ 2. Calls 'print_ident' to format these retrieved ID bytes into the
@    'device8_read_identtxt' message string.
@ 3. Posts the formatted message "device8 JEDEC: MF=0xXX, Type=0xYY, Cap=0xZZ"
@    to the console.
@======================================================================
.global device8_read_ident
.thumb_func
device8_read_ident:
	bl w25q128_read_jedec_id
	bl print_ident

    add   r0, rDEVP, #device8_read_identmsg_OFFSET
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}

@======================================================================
@ device8_erase: Erases a sector of the W25QXX Flash memory. (Command 0x02)
@ This function initiates an erase operation on the flash memory.
@ It calls 'w25q128_erase_sector' with a hardcoded flash address of
@ 0x000000, targeting the first sector (Sector 0) for erasure.
@ After the erase operation, it posts the message
@ "device8 erased directed block" to the console.
@======================================================================
.global device8_erase
.thumb_func
device8_erase:
	MOV_imm32 r0, 0x000000
	bl w25q128_erase_sector
    add   r0, rDEVP, #device8_erase_blockmsg_OFFSET
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}

@======================================================================
@ device8_input: Loads data from command payload into RAM buffer. (Command 0x03)
@ This function reads a count byte from the MoT command payload (r0).
@ It then reads 'count' number of subsequent bytes from the payload and
@ stores them sequentially into the global 'ram_buffer'.
@ After loading the data into RAM, it posts the message
@ "device8 input is in ram" to the console.
@ r0: Input, pointer to command payload (count byte followed by data bytes).
@     Output (for MoT_msgPost), pointer to message link.
@ r1, r2, r3: Used as temporary registers.
@======================================================================
.global device8_input
.thumb_func
device8_input:
	ldrb r2, [r0], #1
	ldr r3, =ram_buffer
loop:
	cmp r2, #0
	beq finished
	ldrb  r1, [r0], #1
	strb r1, [r3], #1
	sub r2, r2, #1
	b loop

finished:
    add   r0, rDEVP, #device8_inputmsg_OFFSET
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}

@======================================================================
@ device8_copy: Copies data from RAM buffer to Flash memory. (Command 0x04)
@ This function writes the contents of the global 'ram_buffer' to the
@ W25QXX flash memory.
@ It sets the destination flash address to 0x000000 and calls
@ 'w25q128_write_ram_buffer' to perform the write operation.
@ After completion, it posts "device8 copy complete" to the console.
@======================================================================
.global device8_copy
.thumb_func
device8_copy:
	ldr r0, =ram_buffer
	MOV_imm32 r1, 0x000000
	bl w25q128_write_ram_buffer
    add   r0, rDEVP, #device8_copy_donemsg_OFFSET
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}

@======================================================================
@ device8_verify: Verifies data in Flash memory against RAM buffer. (Command 0x05)
@ 1. Calls 'device8_read' helper, which reads data from flash (address 0x000000)
@    into the 'received_buffer'.
@ 2. Calls 'w25q128_verify_ram_buffer' to compare the contents of 'ram_buffer'
@    (expected data) with 'received_buffer' (actual data from flash).
@    'w25q128_verify_ram_buffer' returns 1 in r0 for success, 0 for failure.
@ 3. Posts "device8 verification successful" or "device8 verification failed"
@    to the console based on the result.
@======================================================================
.global device8_verify
.thumb_func
device8_verify:
	bl device8_read
	ldr r0, =ram_buffer
	ldr r1, =received_buffer
	bl w25q128_verify_ram_buffer

	cmp r0, #1
	beq success

	add   r0, rDEVP, #device8_verify_failedmsg_OFFSET
	b done

success:
	add   r0, rDEVP, #device8_verify_successmsg_OFFSET
	b done
done:
	MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop {r7, pc}

@======================================================================
@ device8_output: Formats and displays data from 'received_buffer'. (Command 0x06)
@ Reads a count byte from the command payload (r0).
@ Clears the output message string ('device8_outputtxt') using 'clear_output_msg'.
@ Then, it reads 'count' bytes from the 'received_buffer', converts each byte
@ to a two-character hexadecimal string using 'nibble_to_ascii', and appends
@ it to the 'device8_outputtxt' message buffer.
@ Finally, it posts the formatted message containing the hex data to the console.
@ r0: Input, pointer to command payload containing count byte.
@     Output (for MoT_msgPost), pointer to message link.
@ r1-r5: Used as temporary registers.
@======================================================================
.global device8_output
.thumb_func
device8_output:
	bl clear_output_msg
    ldrb  r4, [r0]
    ldr   r3, =received_buffer
    ldr   r2, =device8_outputmsg
    add   r2, r2, #44
loop_msg:
    cmp   r4, #0
    beq   loop_done
    ldrb  r1, [r3], #1
    mov   r5, r1
    lsr   r5, r5, #4
    bl    nibble_to_ascii
    strb  r0, [r2], #1
    mov   r5, r1
    and   r5, r5, #0x0F
    bl    nibble_to_ascii
    strb  r0, [r2], #1
    sub   r4, r4, #1
    b   loop_msg
loop_done:
    MOV_imm32 r0, #device8_outputmsg
    MOV_imm32 r1, consoleMsgs
    bl    MoT_msgPost
    pop   {r7, pc}

@======================================================================
@ device8_skiptask: A minimal MoT task for Device 8.
@ This task performs no specific action for Device 8. It immediately
@ passes execution control to the next scheduled MoT task in the system.
@ It serves as the default idle behavior for this command-driven device.
@======================================================================
.global device8_skiptask
.thumb_func
device8_skiptask:
    ldr rDEVP, [rDEVP, #NEXTTASK]
    ldr pc, [rDEVP, #XEQTASK]

@======================================================================
@ device8_read: Helper function to read data from Flash into 'received_buffer'.
@ This function reads a block of data (RAM_BUFFER_SIZE bytes)
@ from the W25QXX flash memory starting at address 0x000000.
@ The retrieved data is stored in the global 'received_buffer'.
@ It calls 'w25q128_read_ram_buffer' to perform the actual read operation.
@======================================================================
.global device8_read
.thumb_func
device8_read:
	push {r0-r7, lr}
	ldr r1, =received_buffer
	MOV_imm32 r0, 0x000000
	bl w25q128_read_ram_buffer
	pop {r0-r7, pc}

@======================================================================
@ clear_output_msg: Helper function to clear the data portion of 'device8_outputtxt'.
@ This function clears a specific segment (64 bytes starting at an offset of 44 bytes,
@ which is after "device8 output from flash 0x") of the global message string
@ 'device8_outputtxt' by filling it with ASCII '0' characters (decimal 48).
@ This prepares the message buffer for displaying new hex data read from flash.
@======================================================================
.global clear_output_msg
.thumb_func
clear_output_msg:
    push {r0-r7, lr}

    ldr   r2, =device8_outputmsg
    add   r2, r2, #44
    mov   r0, #64
    mov   r1, #48

loop_clr:
    strb r1, [r2], #1
    subs r0, r0, #1
    bne loop_clr

    pop {r0-r7, pc}
