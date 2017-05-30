;
; Check RTC IRQ
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	sei

	clr	$10
	clr	$11
	clr	$12

; Setup timer
	ldaa	#0
	staa	TIMER_CONFIG

; Set 50 Hz interrupts
; 24MHz/50 = 480000 = $75300
;
	ldaa	#$07
	staa	TIMER_PRESCALER
	ldx	#$52FF
	stx	TIMER_PRESCALER+1
; Enable interrupts and start timer
	ldaa	#(TIMER_IEN | TIMER_RUN)
	staa	TIMER_CONFIG

	ldx	#irqhandler
	stx	VIRQ

	cli

loop	ldaa	INPUT_SWKEYS
	staa	LED_8BIT
	bita	#1
	beq	next
	ldx	#but1txt
	bra	print
next	bita	#2
	beq	next2
	ldx	#but2txt
	bra	print
next2	bita	#4
	beq	loop
	ldx	#but3txt
print	jsr	F_UART_PUTS
	bra	loop

but1txt	db	'Button 1 pressed!', 10, 13, 0
but2txt db	'Button 2 pressed!', 10, 13, 0
but3txt db	'Button 3 pressed!', 10, 13, 0

irqhandler proc
; Check if interrupt from timer
	ldaa	TIMER_STATUS
	bita	#TIMER_IRQ
	beq	ret
; Increase time
	ldaa	$10
	staa	LED_HEX
	ldx	$11
	inx
	stx	$11
	cpx	#50
	bne	ret
	clr	$11
	clr	$12
	inc	$10
ret	rti
	endp
