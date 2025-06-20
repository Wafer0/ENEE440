################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_UPPER_SRCS += \
../Src/MoT_devices/SPI.S/device7.S \
../Src/MoT_devices/SPI.S/macros_and_definitions.S 

OBJS += \
./Src/MoT_devices/SPI.S/device7.o \
./Src/MoT_devices/SPI.S/macros_and_definitions.o 

S_UPPER_DEPS += \
./Src/MoT_devices/SPI.S/device7.d \
./Src/MoT_devices/SPI.S/macros_and_definitions.d 


# Each subdirectory must supply rules for building sources it contributes
Src/MoT_devices/SPI.S/%.o: ../Src/MoT_devices/SPI.S/%.S Src/MoT_devices/SPI.S/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m4 -g3 -DDEBUG -c -I"C:/Users/Drach/Downloads/HW7-20250429T024547Z-001/HW7/Project/Inc" -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

clean: clean-Src-2f-MoT_devices-2f-SPI-2e-S

clean-Src-2f-MoT_devices-2f-SPI-2e-S:
	-$(RM) ./Src/MoT_devices/SPI.S/device7.d ./Src/MoT_devices/SPI.S/device7.o ./Src/MoT_devices/SPI.S/macros_and_definitions.d ./Src/MoT_devices/SPI.S/macros_and_definitions.o

.PHONY: clean-Src-2f-MoT_devices-2f-SPI-2e-S

