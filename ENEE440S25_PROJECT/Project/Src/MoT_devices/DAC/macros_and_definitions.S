#define __ASSEMBLY__

.equ NULL,            0
.equ RCC_BASE,        0x40021000
.equ AHB2ENR,         0x4C
.equ AHB2RSTR,        0x2C
.equ GPIOAEN,         (1 << 0)
.equ MODER,           0x00
.equ GPIOA_BASE,      0x48000000
.equ DAC1_BASE,       0x50000800
.equ DAC_DHR12R2,     0x14
.equ DAC1EN,          (1 << 16)
.equ DAC1RST,         (1 << 16)
.equ CR,              0x00
.equ CR_EN2,          (1 << 16)

rDEVP    .req r5

.macro MOV_imm32 reg, constant
    movw \reg, #:lower16:\constant
    movt \reg, #:upper16:\constant
.endm
