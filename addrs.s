RCC_BASE	equ	0x40021000
RCC_CR		equ	0x00
RCC_CFGR	equ	0x04
RCC_APB2ENR	equ	0x18
RCC_APB1ENR	equ	0x1C

PORTA_BASE	equ	0x40010800
GPIOA_CRL	equ	0x00
GPIOA_CRH	equ	0x04
GPIOA_IDR	equ	0x08
GPIOA_ODR	equ	0x0C
GPIOA_BSRR	equ	0x10

PORTB_BASE	equ	0x40010C00
GPIOB_CRL	equ	0x00
GPIOB_CRH	equ	0x04
GPIOB_IDR	equ	0x08
GPIOB_ODR	equ	0x0C
GPIOB_BSRR	equ	0x10

TIM1_BASE	equ	0x40012C00
TIM1_CR1	equ	0x00
TIM1_SR		equ	0x10
TIM1_CCMR1	equ	0x18
TIM1_CCMR2	equ	0x1C
TIM1_CCER	equ	0x20
TIM1_CNT	equ	0x24
TIM1_PSC	equ	0x28
TIM1_ARR	equ	0x2C
TIM1_CCR1	equ	0x34
TIM1_CCR2	equ	0x38
TIM1_CCR3	equ	0x3C
TIM1_CCR4	equ	0x40
TIM1_BDTR	equ	0x44

TIM2_BASE	equ	0x40000000
TIM2_CR1	equ	0x00
TIM2_SR		equ	0x10
TIM2_CCMR1	equ	0x18
TIM2_CCER	equ	0x20
TIM2_CNT	equ	0x24
TIM2_PSC	equ	0x28
TIM2_ARR	equ	0x2C
TIM2_CCR1	equ	0x34
TIM2_BDTR	equ	0x44
	
STK_BASE	equ	0xE000E010
STK_CTRL	equ	0x00
STK_LOAD 	equ	0x04
STK_VAL		equ	0x08

ADC_BASE	equ	0x40012400
ADC_SR		equ	0x00
ADC_CR2		equ	0x08
ADC_SQR3	equ	0x34
ADC_DR		equ	0x4C
	end