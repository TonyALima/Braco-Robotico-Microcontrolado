; Autores: Tony Albert Lima 
;          Samuel Lima Braz 
;
; UNIFEI 2024/1

; Neste programa toda passagem de parametro e realizada em a1 (r0)

	export	initLCD
	export	dataLCD
	export	commandLCD
	export	clearLCD
	export	homeLCD
	export	printDigitLCD
	export	setCursorLCD
	include	addrs.s
; LCD	
; commands
LCD_CLEARDISPLAY	EQU 	0x01  
LCD_RETURNHOME		EQU 	0x02  
LCD_ENTRYMODESET 	EQU	0x04  
LCD_DISPLAYCONTROL	EQU	0x08  
LCD_CURSORSHIFT		EQU	0x10  
LCD_FUNCTIONSET		EQU	0x20 
LCD_SETCGRAMADDR	EQU	0x40 
LCD_SETDDRAMADDR	EQU	0x80 

; flags for display entry mode
LCD_ENTRYRIGHT		EQU	0x00 
LCD_ENTRYLEFT		EQU	0x02  
LCD_ENTRYSHIFTINCREMENT	EQU	0x01  
LCD_ENTRYSHIFTDECREMENT	EQU	0x00  

; flags for display on/off control
LCD_DISPLAYON		EQU	0x04  
LCD_DISPLAYOFF		EQU	0x00 
LCD_CURSORON		EQU	0x02 
LCD_CURSOROFF		EQU	0x00  
LCD_BLINKON		EQU	0x01 
LCD_BLINKOFF		EQU	0x00  

; flags for display/cursor shift
LCD_DISPLAYMOVE		EQU	0x08  
LCD_CURSORMOVE		EQU	0x00  
LCD_MOVERIGHT		EQU	0x04  
LCD_MOVELEFT		EQU	0x00  

; flags for function set
LCD_8BITMODE		EQU	0x10  
LCD_4BITMODE		EQU	0x00  
LCD_2LINE		EQU	0x08  
LCD_1LINE		EQU	0x00  
LCD_5x10DOTS		EQU	0x04  
LCD_5x8DOTS		EQU	0x00  

; flags for backlight control
LCD_BACKLIGHT		EQU	0x08  
LCD_NOBACKLIGHT		EQU	0x00  
	

EN	EQU	0X20 ; Enable bit PB5
RS	EQU	0X1000 ; Register select bit PB12

	area 	mprog, code, readonly
initLCD
	push	{r1-r3, lr}
	
	ldr	r1, =TIM2_BASE
	ldr	r2, =PORTB_BASE
	; timer contando em 1us 
	mov	r3, #35
	str	r3, [r1, #TIM2_PSC]
	; inicia contagem
	ldr	r3, [r1, #TIM2_CR1]
	orr	r3, #0x1
	str	r3, [r1, #TIM2_CR1]
	
	; wait 40ms for lcd initialize
	mov	a1, #40000
	bl	setTimeToWait
	
	;try to set 8bits mode
	bl	waitCCR1
	mov	a1, #0x30
	bl 	write4bits
	bl	pulseEnable
	; wait 4.1ms
	mov	a1, #4200
	bl	setTimeToWait
	
	;try to set 8bits mode
	bl	waitCCR1
	mov	a1, #0x30
	bl 	write4bits
	bl	pulseEnable
	; wait 2ms
	mov	a1, #2000
	bl	setTimeToWait
	
	;try to set 8bits mode
	bl	waitCCR1
	mov	a1, #0x30
	bl 	write4bits
	bl	pulseEnable
	; wait 2ms
	mov	a1, #2000
	bl	setTimeToWait
	
	; set 4bits mode
	bl	waitCCR1
	mov	a1, #0x20
	bl 	write4bits
	bl	pulseEnable
	mov	a1, #2000
	bl	setTimeToWait
	
	mov	a1, #0x28
	bl	commandLCD
	
	mov	a1, #0x06
	bl	commandLCD
	
	mov	a1, #0x0F
	bl	commandLCD
	
	bl	clearLCD

	pop	{r1-r3, lr}
	bx	lr
;-------------------------------------------------------------------

setCursorLCD ; position in a1
	push	{r1-r3, lr}
	ldr	r1, =TIM2_BASE
	ldr	r2, =PORTB_BASE
	
	mov	r3, a1, lsr #4 ; col
	ands	a1, #0x0F ; row
	movne	a1, #0x40
	add	a1, r3
	orr	a1, #LCD_SETDDRAMADDR
	bl	commandLCD
	
	pop	{r1-r3, lr}
	bx	lr
;-------------------------------------------------------------------

printDigitLCD
	push	{r1-r5, lr}
	ldr	r1, =TIM2_BASE
	ldr	r2, =PORTB_BASE
	
	; calcula o valor da centena para escrever na primeira posi��o
	mov	r5, a1
	mov	r4, #100
	udiv	r3, r5, r4
	; converte pro digito em ASCII somando '0' (48)
	add	a1, r3, #'0'
	bl	dataLCD
	; subtrai as centenas do valor original para poder calcular as dezenas
	mul	r3, r4
	sub	r5, r3
	
	; calcula o valor da dezena para escrever na segunda posi��o
	mov	r4, #10
	udiv	r3, r5, r4
	; converte pro digito em ASCII somando '0' (48)
	add	a1, r3, #'0'
	bl	dataLCD
	; subtrai as dezenas do valor para obter as unidades
	mul	r3, r4
	sub	r5, r3
	
	; converte pro digito em ASCII somando '0' (48) e escreve as unidades	
	add	a1, r5, #'0'
	bl	dataLCD
	
	pop	{r1-r5, lr}
	bx	lr
;-------------------------------------------------------------------

clearLCD
	push	{r1-r2, lr}
	ldr	r1, =TIM2_BASE
	ldr	r2, =PORTB_BASE
	
	mov	a1, #LCD_CLEARDISPLAY
	bl	commandLCD
	
	mov	a1, #2000
	bl	setTimeToWait ; set time to command effect
	
	pop	{r1-r2, lr}
	bx	lr
;-------------------------------------------------------------------

homeLCD
	push	{r1-r2, lr}
	ldr	r1, =TIM2_BASE
	ldr	r2, =PORTB_BASE
	
	mov	a1, #LCD_RETURNHOME
	bl	commandLCD
	
	mov	a1, #2000
	bl	setTimeToWait ; set time to command effect
	pop	{r1-r2, lr}
	bx	lr
;-------------------------------------------------------------------

dataLCD
	push	{r1-r3, lr}
	ldr	r1, =TIM2_BASE
	ldr	r2, =PORTB_BASE
	
	bl	waitCCR1
	mov	r3, #RS
	str	r3, [r2, #GPIOB_BSRR] ; set RS
	bl	sendByte
	
	pop	{r1-r3, lr}
	bx	lr
;-------------------------------------------------------------------

commandLCD
	push	{r1-r3, lr}
	ldr	r1, =TIM2_BASE
	ldr	r2, =PORTB_BASE

	bl	waitCCR1
	mov	r3, #RS
	lsl	r3, #16
	str	r3, [r2, #GPIOB_BSRR] ; reset RS
	bl	sendByte
	
	pop	{r1-r3, lr}
	bx	lr
;-------------------------------------------------------------------

sendByte
	push	{r3, lr}
	mov	r3, a1
	
	bl 	write4bits
	bl	pulseEnable
	
	lsl	a1, r3, #4
	bl 	write4bits
	bl	pulseEnable
	
	mov	a1, #40 
	bl	setTimeToWait
	
	pop	{r3, lr}
	bx	lr
;-------------------------------------------------------------------

pulseEnable
	push	{r3, lr}
	mov	a1, #1
	bl	setTimeToWait
	bl	waitCCR1
	
	mov	r3, #EN
	str	r3, [r2, #GPIOB_BSRR]
	
	bl	setTimeToWait
	bl	waitCCR1
	
	lsl	r3, #16
	str	r3, [r2, #GPIOB_BSRR]
	
	bl	setTimeToWait
	bl	waitCCR1
	pop	{r3, lr}
	bx	lr
;-------------------------------------------------------------------

waitCCR1
	push	{r3}
w_pk0	ldrh	r3, [r1, #TIM2_SR]
	ands	r3, #0x2
	beq	w_pk0
	pop	{r3}
	bx	lr
;-------------------------------------------------------------------

setTimeToWait ; time must be in a1
	push	{r3}
	; clear CCR1 flag
	ldrh	r3, [r1, #TIM2_SR]
	bic	r3, #0x2
	strh	r3, [r1, #TIM2_SR]
	; add new a1 time to CCR1
	ldr	r3, [r1, #TIM2_CNT]
	add	r3, a1
	str	r3, [r1, #TIM2_CCR1]
	pop	{r3}
	bx	lr
;-------------------------------------------------------------------

write4bits ; data must be in a1
	push	{r3, lr}
	and	a1, #0xF0 
	lsl	a1, #2
	ldr	r3, [r2, #GPIOB_ODR]
	bic	r3, #0x3C0 ; B6 a B9
	orr	r3, a1
	str	r3, [r2, #GPIOB_ODR]
	pop	{r3, lr}
	bx	lr
;-------------------------------------------------------------------

	end
