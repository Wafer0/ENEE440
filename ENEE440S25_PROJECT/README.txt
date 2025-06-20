ENEE440S25_PROJECT
Author: Andreas Tzitzikas
Date: 2025-05-19

This document outlines the contents and organization of the ENEE440S25 Project submission for the STM32G491 Micro on Tether (MoT).

================================================================================
== Root Directory Structure ==
================================================================================

/
|-- Documentation/
|-- PC/
|-- Project/
|-- README.txt (This file)

================================================================================
== Directory Contents ==
================================================================================

--------------------------------------------------------------------------------
1. Documentation/
--------------------------------------------------------------------------------
   This directory is intended to hold the project's user manual and maintainer document.

   - User_Manual.pdf: Provides operating instructions for all features of the product, targeted at a technical user.
   - Maintainer_Document.pdf: Contains detailed information for engineers who might modify or service the project, including system architecture, design choices, flow charts, etc.

--------------------------------------------------------------------------------
2. PC/
--------------------------------------------------------------------------------
   This directory contains PC-side software and scripts for testing and interacting
   with the STM32G491 MoT system.

   Files at PC/ level:
   - Provided/
     |-- _readme_testterm.txt: Instructions and information about the testterm.exe serial terminal utility.
     |-- 04testterm115200.c: C source code for the testterm.exe serial terminal utility.
     |-- hex2MoT01.c: C source code for a utility to convert HEX strings to MoT command format.
     |-- test_devices1-3.txt: A demonstration test script for MoT devices 1, 2, and 3.
     |-- testterm.exe: Executable for the custom serial terminal program.
   - device3_demo.txt: Test script for demonstrating Device 3 (GPIO functionalities on PA8).
   - device3_demo_result.txt: Captured output from running device3_demo.txt.
   - device4_demo.txt: Test script for demonstrating Device 4 (DAC functionalities).
   - device4_demo_result.txt: Captured output from running device4_demo.txt.
   - device5_demo.txt: Test script for demonstrating Device 5 (ADC functionalities).
   - device5_demo_result.txt: Captured output from running device5_demo.txt.
   - device6_demo.txt: Test script for demonstrating Device 6 (TIM2 Timer functionalities).
   - device6_demo_result.txt: Captured output from running device6_demo.txt.
   - device7_demo.txt: Test script for demonstrating Device 7 (SPI communication).
   - device7_demo_result.txt: Captured output from running device7_demo.txt.
   - device8_demo.txt: Test script for demonstrating Device 8 (W25QXX Flash Memory via SPI).
   - device8_demo_result.txt: Captured output from running device8_demo.txt.
   - hex2MoT01.c: Utility to convert HEX strings to MoT command format (listed in PC/ as well).
   - testterm.exe: Custom serial terminal program (listed in PC/ as well).

--------------------------------------------------------------------------------
3. Project/
--------------------------------------------------------------------------------
   This directory contains all the source code, libraries, and build files for the
   STM32G491 microcontroller firmware.

   Files and subdirectories at Project/ level:
   - Debug/ : Contains the output of the debug build.
     |-- Inc/ : Copied header files for the debug build.
     |-- Src/ : Copied source files for the debug build.
     |-- Startup/ : Copied startup files for the debug build.
     |-- Project.elf: Executable and Linkable Format file for the project (debug build).
     |-- Project.list: Assembly listing file generated during the build.
     |-- Project.map: Linker map file showing memory layout.
     |-- main.d: Dependency file for main.c.
     |-- makefile: Makefile used by the build system for the Debug configuration.
     |-- objects.list: List of object files.
     |-- objects.mk: Makefile include for object files.
     |-- sources.mk: Makefile include for source files.

   - Inc/ : Header files for the firmware.
     |-- MoTstructures.h: Defines data structures for the Micro on Tether (MoT) system.
     |-- MoTsupport.h: Support header files for the MoT system.
     |-- bit-op_macros.S: Assembly language macros for bit manipulation operations.
     |-- handy_macros_v2.h: General-purpose C macros.
     |-- stdint-gcc.h: Standard integer type definitions for GCC.
     |-- stm32G491xx_FLASH.h: STM32G491 microcontroller Flash memory peripheral definitions.
     |-- stm32G491xx_GPIO.h: STM32G491 microcontroller GPIO peripheral definitions.
     |-- stm32G491xx_PWR.h: STM32G491 microcontroller Power Control peripheral definitions.
     |-- stm32G491xx_RCC.h: STM32G491 microcontroller Reset and Clock Control peripheral definitions.
     |-- stm32G491xx_USART1.h: STM32G491 microcontroller USART1 peripheral definitions.
     |-- stm32g491xx.h: Main device header file for the STM32G491 series.
     |-- stm32g491xx_defines.h: Specific preprocessor defines for the STM32G491RE microcontroller.

   - Lib/ : Pre-compiled libraries used in the project.
     |-- libMoTsystem.a: Archive library file for the MoT system.

   - Src/ : Source code files for the firmware.
     |-- HW_userCOM05.S: Assembly code for low-level LPUART1 communication for user console.
     |-- MoT_main03.c: Main C application file for the MoT system.
     |-- MoT_devices/ : Directory containing device-specific drivers.
     |   |-- ADC/
     |   |   |-- device5.S: Assembly driver for Device 5 (ADC).
     |   |   |-- macros_and_definitions.S: Macros and definitions specific to the ADC device.
     |   |-- DAC/
     |   |   |-- device4.S: Assembly driver for Device 4 (DAC).
     |   |   |-- macros_and_definitions.S: Macros and definitions specific to the DAC device.
     |   |-- EXTI1/
     |   |   |-- EXTI1.S: Assembly driver for External Interrupt Line 1.
     |   |   |-- macros_and_definitions.S: Macros and definitions specific to EXTI1.
     |   |-- GPIO/
     |   |   |-- GPIO_init.S: Assembly code for GPIO port initialization.
     |   |   |-- GPIO_input.S: Assembly code for GPIO input functions.
     |   |   |-- GPIO_output.S: Assembly code for GPIO output functions.
     |   |   |-- device3.S: Assembly driver for Device 3 (GPIO operations on PA8).
     |   |   |-- macros_and_definitions.S: Macros and definitions specific to the GPIO device.
     |   |-- Provided/ : Provided base device drivers.
     |   |   |-- MoTdevice_blueBUTTON.S: Assembly driver for the blue user button (PC13).
     |   |   |-- MoTdevice_userLED.S: Assembly driver for the user LED (PA5).
     |   |   |-- userLED.S: Low-level assembly functions for controlling the user LED.
     |   |-- SPI/
     |   |   |-- device7.S: Assembly driver for Device 7 (SPI2 communication).
     |   |   |-- macros_and_definitions.S: Macros and definitions specific to the SPI device.
     |   |-- TIM2/
     |   |   |-- TIM2.S: Assembly code for TIM2 base initialization.
     |   |   |-- TIM2_PWM.S: Assembly code for TIM2 PWM functionalities.
     |   |   |-- TIM2_Pulse.S: Assembly code for TIM2 pulse generation (One-Pulse Mode).
     |   |   |-- TIM2_Trig.S: Assembly code for TIM2 trigger-related functionalities.
     |   |   |-- device6.S: Assembly driver for Device 6 (TIM2 Timer).
     |   |   |-- macros_and_definitions.S: Macros and definitions specific to the TIM2 device.
     |   |-- Utils.S: General utility functions in assembly.
     |   |-- W25QXX/ : Driver for W25QXX series external SPI Flash memory.
     |   |   |-- W25QXX_copy.S: Assembly functions for copying data to/from the W25QXX Flash.
     |   |   |-- W25QXX_init_and_helper.S: Initialization and helper routines for W25QXX.
     |   |   |-- W25QXX_input.S: Assembly functions for handling input data for W25QXX.
     |   |   |-- W25QXX_output.S: Assembly functions for outputting data from W25QXX.
     |   |   |-- W25QXX_read_ident.S: Assembly function to read W25QXX JEDEC identification.
     |   |   |-- W25QXX_verify.S: Assembly functions for verifying data on W25QXX.
     |   |   |-- device8.S: Main assembly driver for Device 8 (W25QXX Flash memory).
     |   |   |-- macros_and_definitions.S: Macros and definitions specific to W25QXX.
     |   |   |-- test.S: Test routines for W25QXX functionality.
     |-- SystemClock_init2.S: Assembly code for system clock configuration (e.g., to 72MHz).
     |-- SysTick_definitions.S: Assembly code for SysTick timer initialization and handler.
     |-- syscalls--left_in_to_quiet_warnings.c: Minimal system call implementations to satisfy linker for newlib C library.

   - Startup/ : Startup code for the microcontroller.
     |-- startup_stm32g491retx.S: Assembly startup file for STM32G491RETx devices.

   - 'Project Debug.launch': Eclipse IDE launch configuration file for debugging.
   - STM32G491RETX_FLASH.ld: Linker script for Flash memory layout.
   - STM32G491RETX_RAM.ld: Linker script for RAM memory layout.
   - README.txt: This file, providing navigation for the project submission.

================================================================================
== Build Instructions ==
================================================================================

The firmware for the STM32G491 can be built using an Eclipse-based IDE (STM32CubeIDE)
with the ARM GCC toolchain.
1. Import the 'Project/' directory into your Eclipse workspace.
2. The project should be pre-configured. Build the project using the "Project Debug"
   configuration.
3. The build output (e.g., Project.elf, Project.bin) will be located in the
   'Project/Debug/' directory.

================================================================================
== Testing Instructions ==
================================================================================

1. Connect the STM32G491 Nucleo board to the PC. Ensure the ST-Link USB connection
   is established, creating a Virtual COM Port. Identify this COM port number.
2. Run the program in debug mode.
3. Run the `testterm.exe` program located in the `PC/` directory, providing the
   COM port and the path to a test script. For example:
   `PC\testterm.exe COM5 PC\device3_demo.txt`
   (Replace COM5 with the actual COM port number).
4. Follow the on-screen prompts from `testterm.exe`. Press 'Enter' to step through
   the script commands and observe the output from the microcontroller.
5. Acceptance test scripts are provided in the `PC/` directory (e.g., `device3_demo.txt`,
   `device4_demo.txt`, etc.). Expected results can be compared against the
   corresponding `*_result.txt` files.

   For specific device tests:
   - Device 3 (GPIO): `PC/device3_demo.txt`. May require manual connection of PA8 to 3.3V/GND or PA5.
   - Device 4 (DAC): `PC/device4_demo.txt`. Oscilloscope recommended for verification.
   - Device 5 (ADC): `PC/device5_demo.txt`. May require connecting PA0 to voltage source/GND/3.3V and triggering PA1.
   - Device 6 (TIM2): `PC/device6_demo.txt`. Oscilloscope recommended for verification of PA5 output.
   - Device 7 (SPI): `PC/device7_demo.txt`. Tests SPI2 communication.
   - Device 8 (W25QXX): `PC/device8_demo.txt`. Tests external Flash memory operations.

Refer to `PC/Provided/_readme_testterm.txt` for more details on `testterm.exe`.
Refer to individual `*.S` and `*.c` files for detailed comments on specific functionalities.
