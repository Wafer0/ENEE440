################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_UPPER_SRCS += \
../Src/MoT_devices/GPIO/GPIO_init.S \
../Src/MoT_devices/GPIO/GPIO_input.S \
../Src/MoT_devices/GPIO/GPIO_output.S \
../Src/MoT_devices/GPIO/device3.S \
../Src/MoT_devices/GPIO/macros_and_definitions.S 

OBJS += \
./Src/MoT_devices/GPIO/GPIO_init.o \
./Src/MoT_devices/GPIO/GPIO_input.o \
./Src/MoT_devices/GPIO/GPIO_output.o \
./Src/MoT_devices/GPIO/device3.o \
./Src/MoT_devices/GPIO/macros_and_definitions.o 

S_UPPER_DEPS += \
./Src/MoT_devices/GPIO/GPIO_init.d \
./Src/MoT_devices/GPIO/GPIO_input.d \
./Src/MoT_devices/GPIO/GPIO_output.d \
./Src/MoT_devices/GPIO/device3.d \
./Src/MoT_devices/GPIO/macros_and_definitions.d 


# Each subdirectory must supply rules for building sources it contributes
Src/MoT_devices/GPIO/%.o: ../Src/MoT_devices/GPIO/%.S Src/MoT_devices/GPIO/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m4 -g3 -DDEBUG -c -I"C:/Users/Drach/Downloads/Final_Project to zip latter/ENEE440S25_PROJECT/Project/Inc" -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

clean: clean-Src-2f-MoT_devices-2f-GPIO

clean-Src-2f-MoT_devices-2f-GPIO:
	-$(RM) ./Src/MoT_devices/GPIO/GPIO_init.d ./Src/MoT_devices/GPIO/GPIO_init.o ./Src/MoT_devices/GPIO/GPIO_input.d ./Src/MoT_devices/GPIO/GPIO_input.o ./Src/MoT_devices/GPIO/GPIO_output.d ./Src/MoT_devices/GPIO/GPIO_output.o ./Src/MoT_devices/GPIO/device3.d ./Src/MoT_devices/GPIO/device3.o ./Src/MoT_devices/GPIO/macros_and_definitions.d ./Src/MoT_devices/GPIO/macros_and_definitions.o

.PHONY: clean-Src-2f-MoT_devices-2f-GPIO

