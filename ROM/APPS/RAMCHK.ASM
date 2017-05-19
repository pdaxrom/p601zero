	include ../DEVMAP.INC

	include ../BOOTROM.INC

RAM_START	equ $ef80
RAM_END		equ $ef82

	org $e000

	ldx	#hello
	jsr	F_UART_PUTS
	jsr	F_UART_PUTS
	jsr	F_UART_PUTS
	jsr	F_UART_PUTS

	ldx	#$1000
	stx	RAM_START
	ldx	#$E000
	stx	RAM_END

	ldaa	#$00
	jsr	fillbyte

	ldaa	#$ff
	jsr	fillbyte

	ldaa	#$aa
	jsr	fillbyte

	ldaa	#$55
	jsr	fillbyte

	ldaa	#$a5
	jsr	fillbyte

	ldaa	#$5a
	jsr	fillbyte

	jsr	fillram

	jmp	F_RESET

fillram proc
	ldaa	#0
loop	ldx	#fillram1
	jsr	F_UART_PUTS
	jsr	F_UART_OUTHEX
	ldx	RAM_START
loopw	staa	0,x
	inx
	cpx	RAM_END
	bne	loopw
	ldx	RAM_START
loopr	ldab	0,x
	cba
	bne	error
	inx
	cpx	RAM_END
	bne	loopr
	ldx	#okay
	jsr	F_UART_PUTS
	inca
	cmpa	#0
	bne	loop
	rts
error	pshx
	ldx	#failed
	jsr	F_UART_PUTS
	tba
	jsr	F_UART_OUTHEX
	ldx	#failed1
	jsr	F_UART_PUTS
	pulx
	ldab	#16
err1	ldaa	0,x
	jsr	F_UART_OUTHEX
	ldaa	#32
	jsr	F_UART_OUT
	decb
	cmpb	#0
	bne	err1
	rts
	endp

fillbyte proc
loop	ldx	#fillram1
	jsr	F_UART_PUTS
	jsr	F_UART_OUTHEX
	ldx	RAM_START
loopw	staa	0,x
	inx
	cpx	RAM_END
	bne	loopw
	ldx	RAM_START
loopr	ldab	0,x
	cba
	bne	error
	inx
	cpx	RAM_END
	bne	loopr
	ldx	#okay
	jsr	F_UART_PUTS
	rts
error	pshx
	ldx	#failed
	jsr	F_UART_PUTS
	tba
	jsr	F_UART_OUTHEX
	ldx	#failed1
	jsr	F_UART_PUTS
	pulx
	ldab	#16
err1	ldaa	0,x
	jsr	F_UART_OUTHEX
	ldaa	#32
	jsr	F_UART_OUT
	decb
	cmpb	#0
	bne	err1
	rts
	endp

hello	db	$0a, $0d, 'External Static RAM CHECK', $0a, $0d, 0
fillram1 db	'Fill RAM with byte ', 0
okay	db	' Okay', 10, 13, 0
failed	db	' Failed ($',0
failed1 db	')', 10, 13, 0
