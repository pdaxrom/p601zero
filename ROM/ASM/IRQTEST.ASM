;
; Check RTC IRQ
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

	include ../BOOTMEM.INC

	org $100

	sei

	ldx	#hello
	int	F_PUTSTR

	ldaa	#01
	staa	IO_L7HI
	inca
	staa	IO_L7LO

	clr	$10
	clr	$11
	clr	$12

; Setup timer
	ldaa	#0
	staa	IO_TIM_CONFIG

; Set 50 Hz interrupts
; 24MHz/50 = 480000 = $75300
;
	ldaa	#$07
	staa	IO_TIM_DIV
	ldx	#$52FF
	stx	IO_TIM_DIV+1
; Enable interrupts and start timer
	ldaa	#(IO_TIM_IEN | IO_TIM_RUN)
	staa	IO_TIM_CONFIG

	ldx	#irqhandler
	stx	VECIRQ

	ldx	#text1
	int	F_PUTSTR

	cli

loop	ldaa	IO_SWKEYS
	staa	IO_L8BIT
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
print	int	F_PUTSTR
	bra	loop

but1txt	db	'Button 1 pressed!', 10, 13, 0
but2txt db	'Button 2 pressed!', 10, 13, 0
but3txt db	'Button 3 pressed!', 10, 13, 0

irqhandler proc
; Check if interrupt from timer
	ldaa	IO_TIM_STATUS
	bita	#IO_TIM_IRQ
	beq	ret
; Increase time
	ldx	$11
	inx
	stx	$11
	cpx	#50
	bne	ret
	clr	$11
	clr	$12
	inc	$10
	ldaa	$10
	staa	IO_L7HI
ret	rts
	endp

hello	db	'IRQ test', 10, 13, 0
text1	db	'Started', 10, 13, 0
