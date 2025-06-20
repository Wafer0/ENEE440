################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_UPPER_SRCS += \
../Src/MoT_devices/EXTI1/EXTI1.S \
../Src/MoT_devices/EXTI1/macros_and_definitions.S 

OBJS += \
./Src/MoT_devices/EXTI1/EXTI1.o \
./Src/MoT_devices/EXTI1/macros_and_definitions.o 

S_UPPER_DEPS += \
./Src/MoT_devices/EXTI1/EXTI1.d \
./Src/MoT_devices/EXTI1/macros_and_definitions.d 


# Each subdirectory must supply rules for building sources it contributes
Src/MoT_devices/EXTI1/%.o: ../Src/MoT_devices/EXTI1/%.S Src/MoT_devices/EXTI1/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m4 -g3 -DDEBUG -c -I"C:/Users/Drach/Downloads/Final_Project to zip latter/ENEE440S25_PROJECT/Project/Inc" -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

clean: clean-Src-2f-MoT_devices-2f-EXTI1

clean-Src-2f-MoT_devices-2f-EXTI1:
	-$(RM) ./Src/MoT_devices/EXTI1/EXTI1.d ./Src/MoT_devices/EXTI1/EXTI1.o ./Src/MoT_devices/EXTI1/macros_and_definitions.d ./Src/MoT_devices/EXTI1/macros_and_definitions.o

.PHONY: clean-Src-2f-MoT_devices-2f-EXTI1

