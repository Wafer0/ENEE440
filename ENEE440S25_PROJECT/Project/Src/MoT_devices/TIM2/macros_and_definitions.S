#define __ASSEMBLY__

.macro MOV_imm32 reg, constant
    movw \reg, #:lower16:\constant
    movt \reg, #:upper16:\constant
.endm

.equ NULL,                    0

.equ ACTUAL_PCLK1_HZ,         170000000
.equ TARGET_TIM_CLOCK_HZ,     1000000

.equ RCC_BASE,                0x40021000
.equ RCC_AHB2ENR,             0x4C
.equ RCC_APB1ENR1,            0x58

.equ GPIOA_BASE,              0x48000000
.equ GPIOA_MODER,             0x00
.equ GPIOA_OTYPER,            0x04
.equ GPIOA_OSPEEDR,           0x08
.equ GPIOA_PUPDR,             0x0C
.equ GPIOA_IDR,               0x10
.equ GPIOA_ODR,               0x14
.equ GPIOA_BSRR,              0x18
.equ GPIOA_LCKR,              0x1C
.equ GPIOA_AFRL,              0x20
.equ GPIOA_AFRH,              0x24

.equ GPIOAEN_Pos,             0
.equ GPIOAEN_BIT,             (1 << GPIOAEN_Pos)

.equ PA0_MODER_Pos,           (0 * 2)
.equ PA0_AFRL_Pos,            (0 * 4)

.equ PA5_MODER_Pos,           (5 * 2)
.equ PA5_OTYPER_Pos,          5
.equ PA5_OSPEEDR_Pos,         (5 * 2)
.equ PA5_PUPDR_Pos,           (5 * 2)
.equ PA5_AFRL_Pos,            (5 * 4)
.equ PA5_AF_TIM2_CH1,         (0b0001 << PA5_AFRL_Pos)

.equ PA6_MODER_Pos,           (6 * 2)
.equ PA6_PUPDR_Pos,           (6 * 2)
.equ PA6_AFRL_Pos,            (6 * 4)

.equ GPIO_AF1_TIM2,           0x01

.equ TIM2_BASE,               0x40000000
.equ TIM2EN_Pos,              0
.equ TIM2EN_BIT,              (1 << TIM2EN_Pos)

.equ TIMx_CR1,                0x00
.equ TIMx_CR2,                0x04
.equ TIMx_SMCR,               0x08
.equ TIMx_DIER,               0x0C
.equ TIMx_SR,                 0x10
.equ TIMx_EGR,                0x14
.equ TIMx_CCMR1,              0x18
.equ TIMx_CCMR2,              0x1C
.equ TIMx_CCER,               0x20
.equ TIMx_CNT,                0x24
.equ TIMx_PSC,                0x28
.equ TIMx_ARR,                0x2C
.equ TIMx_CCR1,               0x34
.equ TIMx_CCR2,               0x38
.equ TIMx_CCR3,               0x3C
.equ TIMx_CCR4,               0x40

.equ TIMx_CR1_CEN,            (1 << 0)
.equ TIMx_CR1_OPM,            (1 << 3)
.equ TIMx_CR1_ARPE,           (1 << 7)
.equ TIMx_CR1_DIR,            (1 << 4)
.equ TIMx_CR1_CMS,            (0b11 << 5)

.equ TIM_CR1_CEN_Pos,         0
.equ TIM_CR1_CEN_Msk,         (1 << TIM_CR1_CEN_Pos)
.equ TIM_CR1_OPM_Pos,         3
.equ TIM_CR1_OPM_Msk,         (1 << TIM_CR1_OPM_Pos)
.equ TIM_CR1_ARPE_Pos,        7
.equ TIM_CR1_ARPE_Msk,        (1 << TIM_CR1_ARPE_Pos)

.equ TIMx_CCMR1_OC1M_PWM1,    (0b110 << 4)
.equ TIMx_CCMR1_OC1PE,        (1 << 3)

.equ TIM_CCMR1_CC1S_Pos,      0
.equ TIM_CCMR1_CC1S_Msk,      (0b11 << TIM_CCMR1_CC1S_Pos)
.equ TIM_CCMR1_OC1M_Pos,      4
.equ TIM_CCMR1_OC1M_Msk_Low,  (0b111 << TIM_CCMR1_OC1M_Pos)
.equ TIM_CCMR1_OC1M_Msk_High_Bit_Pos, 16
.equ TIM_CCMR1_OC1M_Msk_High, (1 << TIM_CCMR1_OC1M_Msk_High_Bit_Pos)
.equ TIM_CCMR1_IC1F_Pos,      4
.equ TIM_CCMR1_IC1F_Msk,      (0b1111 << TIM_CCMR1_IC1F_Pos)

.equ TIM_CCMR1_CC2S_Pos,      8
.equ TIM_CCMR1_CC2S_Msk,      (0b11 << TIM_CCMR1_CC2S_Pos)
.equ TIM_CCMR1_IC2F_Pos,      12
.equ TIM_CCMR1_IC2F_Msk,      (0b1111 << TIM_CCMR1_IC2F_Pos)

.equ TIMx_CCER_CC1E,          (1 << 0)
.equ TIM_CCER_CC1E_Pos,       0
.equ TIM_CCER_CC1E_Msk,       (1 << TIM_CCER_CC1E_Pos)
.equ TIM_CCER_CC1P_Pos,       1
.equ TIM_CCER_CC1P_Msk,       (1 << TIM_CCER_CC1P_Pos)
.equ TIM_CCER_CC1NP_Pos,      3
.equ TIM_CCER_CC1NP_Msk,      (1 << TIM_CCER_CC1NP_Pos)

.equ TIM_CCER_CC2E_Pos,       4
.equ TIM_CCER_CC2E_Msk,       (1 << TIM_CCER_CC2E_Pos)
.equ TIM_CCER_CC2P_Pos,       5
.equ TIM_CCER_CC2P_Msk,       (1 << TIM_CCER_CC2P_Pos)
.equ TIM_CCER_CC2NP_Pos,      7
.equ TIM_CCER_CC2NP_Msk,      (1 << TIM_CCER_CC2NP_Pos)

.equ TIMx_EGR_UG,             (1 << 0)

.equ TIM_SMCR_SMS_Pos,        0
.equ TIM_SMCR_SMS_Msk,        (0b111 << TIM_SMCR_SMS_Pos)
.equ TIM_SMCR_SMS_RESET_MODE, (0b100 << TIM_SMCR_SMS_Pos)
.equ TIM_SMCR_SMS_ECM1,       (0b111 << TIM_SMCR_SMS_Pos)
.equ TIM_SMCR_TS_Pos,         4
.equ TIM_SMCR_TS_Msk,         (0b111 << TIM_SMCR_TS_Pos)
.equ TIM_SMCR_TS_TI1FP1,      (0b101 << TIM_SMCR_TS_Pos)

.equ TIM_SR_CC1IF_Pos,        1
.equ TIM_SR_CC1IF_Msk,        (1 << TIM_SR_CC1IF_Pos)
.equ TIM_SR_CC2IF_Pos,        2
.equ TIM_SR_CC2IF_Msk,        (1 << TIM_SR_CC2IF_Pos)
.equ TIM_SR_UIF_Pos,          0
.equ TIM_SR_UIF_Msk,          (1 << TIM_SR_UIF_Pos)
