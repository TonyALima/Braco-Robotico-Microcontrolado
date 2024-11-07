; Autores: Tony Albert Lima 
;          Samuel Lima Braz 
;
; UNIFEI 2024/1

; Neste programa toda passagem de parametro e realizada em a1 (r0)
	
	export	__main
	export	__isrST
	import	initLCD
	import	dataLCD
	import	homeLCD
	import	printDigitLCD
	import	setCursorLCD
	include	addrs.s

	area	consts, data, readonly
limits	; limites de angulo de cada motor
m1	DCB	00, 180 
m2	DCB	130, 160
m3	DCB	30, 120
m4	DCB	50, 160

	area 	prog, code, readonly
__main
;------------- Setup --------------------------------
	ldr	r1, =RCC_BASE
	
	ldr	r3, [r1, #RCC_CR]
	orr	r3, #0x10000 	; hse on
	str	r3, [r1, #RCC_CR]

i_pk2	ldr	r3, [r1, #RCC_CR]
	ands	r3, #0x20000
	beq	i_pk2
	
	ldr	r3, [r1, #RCC_CFGR]
	bic	r3, #0x3F0000
	orr	r3, #0x1F0000	; pll mul = 9, pll src = hse/2
	str	r3, [r1, #RCC_CFGR]

i_pk0	ldr	r3, [r1, #RCC_CR]
	ands	r3, #0x2
	beq	i_pk0
	
	ldr	r3, [r1, #RCC_CR]
	orr	r3, #0x1000000 	; pll on
	str	r3, [r1, #RCC_CR]
	
	ldr	r3, [r1, #RCC_CFGR]
	orr	r3, #0x2	; system clock = pll
	orr	r3, #0x4000	; adc prescaler = 4
	str	r3, [r1, #RCC_CFGR]
	
i_pk1	ldr	r3, [r1, #RCC_CR]
	ands	r3, #0x2000000
	beq	i_pk1
	
	; sysclk = 36MHz
	
	; liga timer clk do timer 1, PORTA e B e ADC1
	ldr	r3, [r1, #RCC_APB2ENR]
	orr	r3, #0x20C
	orr	r3, #0x800
	str	r3, [r1, #RCC_APB2ENR]
	; liga timer clk do timer 2
	ldr	r3, [r1, #RCC_APB1ENR]
	orr	r3, #0x1
	str	r3, [r1, #RCC_APB1ENR]	

	; Configura PA8 a PA11 como saida do timer 1 ch1 a ch4
	ldr	r2, =PORTA_BASE
	ldr	r3, [r2, #GPIOA_CRH]
	bic	r3, #0x00FF
	bic	r3, #0xFF00
	orr	r3, #0x00DD
	orr	r3, #0xDD00
	str	r3, [r2, #GPIOA_CRH]
	
	; Configura PA0 a PA7 como entrada pull-up ou pull-down
	ldr	r3, [r2, #GPIOA_CRL]
	bic	r3, #0xFFFFFFFF
	orr	r3, #0x88888888
	str	r3, [r2, #GPIOA_CRL]
	; Configura entradas para pull-up
	ldr	r3, [r2, #GPIOA_ODR]
	orr	r3, #0xFF
	str	r3, [r2, #GPIOA_ODR]
	
	; Configura de PB5 a PB9 e PB12 como saida push-pull (lcd) 
	ldr 	r1, =PORTB_BASE
	ldr	r3, [r1, #GPIOB_CRL]
	bic	r3, #0x00F00000
	bic	r3, #0xFF000000
	orr	r3, #0x00200000
	orr	r3, #0x22000000
	str	r3, [r1, #GPIOB_CRL]
	ldr	r3, [r1, #GPIOB_CRH]
	bic	r3, #0xFF
	bic	r3, #0xF0000
	orr	r3, #0x22
	orr	r3, #0x20000
	str	r3, [r1, #GPIOB_CRH]
	ldr	r3, [r1, #GPIOB_ODR]
	bic	r3, #0x13E0
	str	r3, [r1, #GPIOB_ODR]
	
	; PB0 input analog
	ldr	r3, [r1, #GPIOB_CRL]
	bic	r3, #0xF
	str	r3, [r1, #GPIOB_CRL]
	
	ldr	r12, =ADC_BASE
	ldr	r3, [r12, #ADC_CR2]
	orr	r3, #1 ; adon
	str	r3, [r12, #ADC_CR2]
	
	mov	r3, #9 ;~1us tempo de estabilizacao adc
i_pk3	subs	r3, #1
	bne	i_pk3
	
	ldr	r3, [r12, #ADC_SQR3]
	orr	r3, #8 ; ch=8 PB0
	str	r3, [r12, #ADC_SQR3]
	
	ldr	r1, =STK_BASE
	mov	r3, #4499 ;1ms
	str	r3, [r1, #STK_LOAD]
	
	ldr	r3, [r1, #STK_CTRL]
	orr	r3, #3 ; liga contagem e interrupcao
	str	r3, [r1, #STK_CTRL]
	
	ldr	r1, =TIM1_BASE
	
	; prescaler para resultar em f = 36MHz/200 = 180kHz
	; Essa frequencia resulta em 1 contagem do timer ser equivalente a 0.5° de movimento no motor
	mov	r3, #199
	str	r3, [r1, #TIM1_PSC]
	
	; contagem maxima do pwm, periodo = 20ms
	mov	r3, #3599
	str	r3, [r1, #TIM1_ARR]
	
	; configura modo do timer para PWM1 em todos os canais
	mov	r4, #0x6060
	ldr	r3, [r1, #TIM1_CCMR1]
	orr	r3, r4
	str	r3, [r1, #TIM1_CCMR1]
	ldr	r3, [r1, #TIM1_CCMR2]
	orr	r3, r4
	str	r3, [r1, #TIM1_CCMR2]
	
	; inicia contagem
	ldr	r3, [r1, #TIM1_CR1]
	orr	r3, #0x1
	str	r3, [r1, #TIM1_CR1]
	
	; habilita a saida de todos os canais
	mov	r4, #0x1111
	ldr	r3, [r1, #TIM1_CCER]
	orr	r3, r4
	str	r3, [r1, #TIM1_CCER]
	
	; habilita main output
	ldr	r3, [r1, #TIM1_BDTR]
	orr	r3, #0x8000
	str	r3, [r1, #TIM1_BDTR]
		
	mov	r3, #260 ; posicao inicial dos motores
	str	r3, [r1, #TIM1_CCR1]
	mov	r3, #380
	str	r3, [r1, #TIM1_CCR2]
	mov	r3, #160
	str	r3, [r1, #TIM1_CCR3]
	mov	r3, #380
	str	r3, [r1, #TIM1_CCR4]
	
	; inicia lcd
	bl	initLCD

;------------- Inicio do loop infinito -----------------------------
	; espera acabar contagem do systick para executar rotina
loop	wfi
	ldr	r3, [r12, #ADC_CR2]
	orr	r3, #1 ; inicia conversao adc
	str	r3, [r12, #ADC_CR2]
	
	ldr	r3, [r1, #TIM1_SR] ; so atualiza LDC de 20 em 20ms
	ands	r4, r3, #0x1 
	beq	pk0
	bic	r3, #0x1 ; lipa flag 
	str	r3, [r1, #TIM1_SR]
	
	bl	atualizaLCD
	
pk0	bl	readButtons ; return read in a1
	mov	r6, a1 ; guarda em r6
	
	; ponteiros
	add	r11, r1, #TIM1_CCR1  ; ponteiro inical 
	add	r10, r1, #TIM1_CCR4 + 4 ; ponteiro final
	ldr	r7, =limits
	
forEachServo	; loop para cada servo
	ldrb	r4, [r7], #1 ; le limite 
	ldr	r3, [r11] ; le angulo atual
	
	; se botao nao pressionado pula decremento
	ands	r5, r6, #0x1
	bne	pk1  
	
	; converte limite de angulo para valor de duty
	lsl	r4, #1
	add	r4, #80
	
	cmp	r3, r4 ; testa o limite inferior
	subhi	r3, #1 ; subtrai decremento se nao passar

pk1	ldrb	r4, [r7], #1 ; le limite 
	ands	r5, r6, #0x2
	bne	pk2  ; se botao nao pressionado pula incremento
	
	; converte limite de angulo para valor de duty
	lsl	r4, #1
	add	r4, #80
	
	cmp	r3, r4 ; testa o limite superior
	addlo	r3, #1 ; adciona incremento se nao passar
	
	; escrve o novo pwm
pk2	str	r3, [r11], #4
	
	lsr	r6, #2 ; desloca para proximos botoes
	
	cmp	r11, r10 ; verifica final do loop
	bne	forEachServo
	
	; atualiza velociade do loop principal (stk interrupt)
	bl	velCtrl
	
	; retorna ao inicio do programa
	b	loop
;------------- Fim do loop infinito --------------------------------

;------------- Inicio funcoes --------------------------------------
velCtrl
	push	{r3-r5, lr}

	ldr	r3, [r12, #ADC_DR]
	
	mov	r4, #4096
	sub	r3, r4, r3 ; complemento, menor velociade maior o tempo
	
	mov	r4, #25 ; range 0 a ~20ms
	mul	r3, r4
	
	ldr	r5, =STK_BASE
	str	r3, [r5, #STK_LOAD]
	
	pop	{r3-r5, lr}
	bx	lr
;-------------------------------------------------------------------

atualizaLCD
	push	{r3-r5, lr}
	
	; volta pro inicio do lcd
	mov	a1, #0x00
	bl	setCursorLCD
	
	add	r4, r1, #TIM1_CCR1 ;ponteiro inicial
	add	r5, r1, #TIM1_CCR4 + 4;ponteiro final
	
eachAng	ldr	r3, [r4], #4
	
	; calcula o angulo = (ccr - 80)/2 e imprime no LCD
	sub	a1, r3, #80
	asr	a1, #1	
	bl	printDigitLCD
	
	mov	a1, #' '
	bl	dataLCD
	
	cmp	r4, r5; verifica final do loop
	bne	eachAng
	
; atualizando velocidade
	mov	a1, #0x01
	bl	setCursorLCD
	mov	a1, #'V'
	bl	dataLCD
	mov	a1, #':'
	bl	dataLCD

	ldr	r3, [r12, #ADC_DR]
	; range 0 a 100
	mov	a1, r3
	mov	r4, #100
	mul	a1, r4
	mov	r4, #4096
	udiv	a1, r4
	bl	printDigitLCD
	
	mov	a1, #'%'
	bl	dataLCD
	
	pop	{r3-r5, lr}
	bx 	lr
;-------------------------------------------------------------------

readButtons ; retorna em a1 a leitura dos botoes com debounce
	push	{r3-r5}
	
	mov	r3, #3
	mov 	a1, #0x00
rb_pk0	
	ldr	r4, [r2, #GPIOA_IDR]
	orr	a1, r4
	
	mov	r5, #4500 ;~0.5ms
rb_pk1	subs	r5, #1
	bne	rb_pk1
	
	subs	r3, #1
	bne	rb_pk0
	
	pop	{r3-r5}
	bx	lr
;-------------------------------------------------------------------

__isrST
	bx	lr
	end