################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_UPPER_SRCS += \
../Src/MoT_devices/W25QXX/W25QXX_copy_erase.S \
../Src/MoT_devices/W25QXX/W25QXX_init_and_helper.S \
../Src/MoT_devices/W25QXX/W25QXX_read.S \
../Src/MoT_devices/W25QXX/W25QXX_read_ident.S \
../Src/MoT_devices/W25QXX/W25QXX_verify.S \
../Src/MoT_devices/W25QXX/device8.S \
../Src/MoT_devices/W25QXX/macros_and_definitions.S 

OBJS += \
./Src/MoT_devices/W25QXX/W25QXX_copy_erase.o \
./Src/MoT_devices/W25QXX/W25QXX_init_and_helper.o \
./Src/MoT_devices/W25QXX/W25QXX_read.o \
./Src/MoT_devices/W25QXX/W25QXX_read_ident.o \
./Src/MoT_devices/W25QXX/W25QXX_verify.o \
./Src/MoT_devices/W25QXX/device8.o \
./Src/MoT_devices/W25QXX/macros_and_definitions.o 

S_UPPER_DEPS += \
./Src/MoT_devices/W25QXX/W25QXX_copy_erase.d \
./Src/MoT_devices/W25QXX/W25QXX_init_and_helper.d \
./Src/MoT_devices/W25QXX/W25QXX_read.d \
./Src/MoT_devices/W25QXX/W25QXX_read_ident.d \
./Src/MoT_devices/W25QXX/W25QXX_verify.d \
./Src/MoT_devices/W25QXX/device8.d \
./Src/MoT_devices/W25QXX/macros_and_definitions.d 


# Each subdirectory must supply rules for building sources it contributes
Src/MoT_devices/W25QXX/%.o: ../Src/MoT_devices/W25QXX/%.S Src/MoT_devices/W25QXX/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m4 -g3 -DDEBUG -c -I"C:/Users/Drach/Downloads/Final_Project to zip latter/ENEE440S25_PROJECT/Project/Inc" -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

clean: clean-Src-2f-MoT_devices-2f-W25QXX

clean-Src-2f-MoT_devices-2f-W25QXX:
	-$(RM) ./Src/MoT_devices/W25QXX/W25QXX_copy_erase.d ./Src/MoT_devices/W25QXX/W25QXX_copy_erase.o ./Src/MoT_devices/W25QXX/W25QXX_init_and_helper.d ./Src/MoT_devices/W25QXX/W25QXX_init_and_helper.o ./Src/MoT_devices/W25QXX/W25QXX_read.d ./Src/MoT_devices/W25QXX/W25QXX_read.o ./Src/MoT_devices/W25QXX/W25QXX_read_ident.d ./Src/MoT_devices/W25QXX/W25QXX_read_ident.o ./Src/MoT_devices/W25QXX/W25QXX_verify.d ./Src/MoT_devices/W25QXX/W25QXX_verify.o ./Src/MoT_devices/W25QXX/device8.d ./Src/MoT_devices/W25QXX/device8.o ./Src/MoT_devices/W25QXX/macros_and_definitions.d ./Src/MoT_devices/W25QXX/macros_and_definitions.o

.PHONY: clean-Src-2f-MoT_devices-2f-W25QXX

