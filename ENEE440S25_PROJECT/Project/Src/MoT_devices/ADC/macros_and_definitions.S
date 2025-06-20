#define __ASSEMBLY__

.macro MOV_imm32 reg, constant
    movw \reg, #:lower16:\constant
    movt \reg, #:upper16:\constant
.endm

    .equ RCC_BASE,      0x40021000
    .equ GPIOA_BASE,    0x48000000
    .equ DAC1_BASE,     0x50000800
    .equ ADC1_BASE,     0x50000000

    .equ AHB2RSTR,      0x2C
    .equ AHB2ENR,       0x4C
    .equ RCC_CCIPR,     0x88
    .equ RCC_APB1ENR1,  0x58

    .equ ADC_CR,        0x08
    .equ ADC_ISR,       0x00
    .equ ADC_DR,        0x40
    .equ ADC_SQR1,      0x30
    .equ DEEPPWD,       (1 << 29)
    .equ ADVREGEN,      (1 << 28)
    .equ ADCAL,         (1 << 31)
    .equ ADEN,          (1 << 0)
    .equ ADSTART,       (1 << 2)
    .equ ADRDY,         (1 << 0)
    .equ EOC,           (1 << 2)
    .equ ADC12SEL,      (0b10 << 28)
    .equ ADCEN,         (1 << 13)
    .equ ADCRST,        (1 << 13)

    .equ GPIOAEN,       (1 << 0)
    .equ GPIOARST,      (1 << 0)
    .equ MODER,         0x00
    .equ PA0,           0

    .equ DAC_DHR12R2,   0x14

    .equ NULL,          0
