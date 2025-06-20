#define __ASSEMBLY__

.macro MOV_imm32 reg, constant
    movw \reg, #:lower16:\constant
    movt \reg, #:upper16:\constant
.endm

.equ RCC_BASE,        0x40021000
.equ RCC_AHB2ENR,     0x4C
.equ RCC_APB1ENR1,    0x58
.equ RCC_APB1RSTR1,   0x38

.equ GPIOB_BASE,      0x48000400
.equ GPIOx_MODER,     0x00
.equ GPIOx_OTYPER,    0x04
.equ GPIOx_OSPEEDR,   0x08
.equ GPIOx_PUPDR,     0x0C
.equ GPIOx_BSRR,      0x18
.equ GPIOx_AFRH,      0x24

.equ SPI2_BASE,       0x40003800
.equ SPIx_CR1,        0x00
.equ SPIx_CR2,        0x04
.equ SPIx_SR,         0x08
.equ SPIx_DR,         0x0C

.equ RCC_AHB2ENR_GPIOBEN, (1 << 1)
.equ RCC_APB1ENR1_SPI2EN, (1 << 14)
.equ RCC_APB1RSTR1_SPI2RST,(1 << 14)

.equ GPIO_MODER_INPUT,    0b00
.equ GPIO_MODER_OUTPUT,   0b01
.equ GPIO_MODER_AF,       0b10
.equ GPIO_MODER_ANALOG,   0b11

.equ GPIO_OSPEEDR_VHIGH,  0b11

.equ SPI_CR1_SPE,     (1 << 6)
.equ SPI_CR1_MSTR,    (1 << 2)
.equ SPI_CR1_BR_Pos,  3
.equ SPI_CR1_BR_DIV16,(0b011 << SPI_CR1_BR_Pos)
.equ SPI_CR1_CPOL,    (1 << 1)
.equ SPI_CR1_CPHA,    (1 << 0)
.equ SPI_CR1_SSM,     (1 << 9)
.equ SPI_CR1_SSI,     (1 << 8)

.equ SPI_CR2_DS_Pos,  8
.equ SPI_CR2_DS_8BIT, (0b0111 << SPI_CR2_DS_Pos)
.equ SPI_CR2_FRXTH,   (1 << 12)

.equ SPI_SR_RXNE,     (1 << 0)
.equ SPI_SR_TXE,      (1 << 1)
.equ SPI_SR_BSY,      (1 << 7)

.equ PIN12, 12
.equ PIN13, 13
.equ PIN14, 14
.equ PIN15, 15

.equ AF5, 0b0101
