#define __ASSEMBLY__

    .syntax unified
    .thumb

    .macro  MOV_imm32           reg, constant
        movw    \reg, #:lower16:\constant
        movt    \reg, #:upper16:\constant
    .endm

    .equ    RCC_BASE,           0x40021000
    .equ    AHB2RSTR,           0x2C
    .equ    AHB2ENR,            0x4C
    .equ    DAC1RST,            (1<<16)
    .equ    DAC1EN,             (1<<16)
    .equ    GPIOARST,           (1<<0)
    .equ    GPIOAEN,            (1<<0)
    .equ    NULL,               0
    .equ    GPIOx_BSRR,         0x18

    .equ    MODER,              0x00
    .equ    OTYPER,             0x04
    .equ    OSPEEDR,            0x08
    .equ    OPUPDR,             0x0C
    .equ    IDR,                0x10
    .equ    ODR,                0x14
    .equ    BSRR,               0x18
    .equ    LCKR,               0x1C
    .equ    AFRL,               0x20
    .equ    AFRH,               0x24
    .equ    BRR,                0x28
    .equ    ASCR,               0x2C

    .equ    PA5,                5
    .equ    PA0,                0
    .equ    PA8,                8

    .equ    NULL,               0
    .equ    RCC_BASE,           0x40021000
    .equ    AHB2ENR,            0x4C
    .equ    AHB2RSTR,           0x2C
    .equ    GPIOAEN,            (1 << 0)
    .equ    MODER,              0x00
    .equ    GPIOA_BASE,         0x48000000
    .equ    DAC1_BASE,          0x50000800
    .equ    DAC_DHR12R2,        0x14
    .equ    DAC1EN,             (1 << 16)
    .equ    DAC1RST,            (1 << 16)
    .equ    CR,                 0x00
    .equ    CR_EN2,             (1 << 16)
