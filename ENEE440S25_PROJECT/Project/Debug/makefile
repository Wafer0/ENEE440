################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include Startup/subdir.mk
-include Src/MoT_devices/W25QXX/subdir.mk
-include Src/MoT_devices/TIM2/subdir.mk
-include Src/MoT_devices/SPI/subdir.mk
-include Src/MoT_devices/Provided/subdir.mk
-include Src/MoT_devices/GPIO/subdir.mk
-include Src/MoT_devices/EXTI1/subdir.mk
-include Src/MoT_devices/DAC/subdir.mk
-include Src/MoT_devices/ADC/subdir.mk
-include Src/MoT_devices/subdir.mk
-include Src/subdir.mk
-include Inc/subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(S_DEPS)),)
-include $(S_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
endif

-include ../makefile.defs

OPTIONAL_TOOL_DEPS := \
$(wildcard ../makefile.defs) \
$(wildcard ../makefile.init) \
$(wildcard ../makefile.targets) \


BUILD_ARTIFACT_NAME := Project
BUILD_ARTIFACT_EXTENSION := elf
BUILD_ARTIFACT_PREFIX :=
BUILD_ARTIFACT := $(BUILD_ARTIFACT_PREFIX)$(BUILD_ARTIFACT_NAME)$(if $(BUILD_ARTIFACT_EXTENSION),.$(BUILD_ARTIFACT_EXTENSION),)

# Add inputs and outputs from these tool invocations to the build variables 
EXECUTABLES += \
Project.elf \

MAP_FILES += \
Project.map \

SIZE_OUTPUT += \
default.size.stdout \

OBJDUMP_LIST += \
Project.list \


# All Target
all: main-build

# Main-build Target
main-build: Project.elf secondary-outputs

# Tool invocations
Project.elf Project.map: $(OBJS) $(USER_OBJS) C:\Users\Drach\Downloads\Final_Project\ to\ zip\ latter\ENEE440S25_PROJECT\Project\STM32G491RETX_FLASH.ld makefile objects.list $(OPTIONAL_TOOL_DEPS)
	arm-none-eabi-gcc -o "Project.elf" @"objects.list" $(USER_OBJS) $(LIBS) -mcpu=cortex-m4 -T"C:\Users\Drach\Downloads\Final_Project to zip latter\ENEE440S25_PROJECT\Project\STM32G491RETX_FLASH.ld" --specs=nosys.specs -Wl,-Map="Project.map" -Wl,--gc-sections -static -L"C:/Users/Drach/Downloads/Final_Project to zip latter/ENEE440S25_PROJECT/Project/Lib" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -Wl,--start-group -lc -lm -Wl,--end-group
	@echo 'Finished building target: $@'
	@echo ' '

default.size.stdout: $(EXECUTABLES) makefile objects.list $(OPTIONAL_TOOL_DEPS)
	arm-none-eabi-size  $(EXECUTABLES)
	@echo 'Finished building: $@'
	@echo ' '

Project.list: $(EXECUTABLES) makefile objects.list $(OPTIONAL_TOOL_DEPS)
	arm-none-eabi-objdump -h -S $(EXECUTABLES) > "Project.list"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) Project.elf Project.list Project.map default.size.stdout
	-@echo ' '

secondary-outputs: $(SIZE_OUTPUT) $(OBJDUMP_LIST)

fail-specified-linker-script-missing:
	@echo 'Error: Cannot find the specified linker script. Check the linker settings in the build configuration.'
	@exit 2

warn-no-linker-script-specified:
	@echo 'Warning: No linker script specified. Check the linker settings in the build configuration.'

.PHONY: all clean dependents main-build fail-specified-linker-script-missing warn-no-linker-script-specified

-include ../makefile.targets
