;
; ram pages check
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	jsr	F_UART_PUTS

	ldaa	#$00
	staa	$e6f1

	clra
loop	staa	$e6f0
	staa	$c000
	tab
	addb	#$10
	stab	$d000
	inca
	cmpa	#16
	bne	loop

	bsr	readpages

	ldx	#hello1
	jsr	F_UART_PUTS

	ldaa	#$01
	staa	$e6f1

	clra
loop2	staa	$e6f0
	tab
	negb
	stab	$c000
	addb	#$10
	stab	$d000
	inca
	cmpa	#16
	bne	loop2

	bsr	readpages

	jmp	F_RESET

readpages proc
	clrb
loop	stab	$e6f0
	ldx	#page
	jsr	F_UART_PUTS
	tba
	jsr	F_UART_OUTHEX
	ldaa	#32
	jsr	F_UART_OUT
	ldaa	$c000
	jsr	F_UART_OUTHEX
	ldaa	#32
	jsr	F_UART_OUT
	ldaa	$d000
	jsr	F_UART_OUTHEX
	incb
	cmpb	#16
	bne	loop
	rts
	endp

hello	db	10, 13, 'RAMPAGES CHECK', 0
hello1	db	10, 13, 'RAMPAGES CHECK LOCK', 0
page	db	10, 13, 'Page ', 0
