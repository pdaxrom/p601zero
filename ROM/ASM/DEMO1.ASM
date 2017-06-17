	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	jsr	F_UART_PUTS
	ldx	#hello1
	jsr	F_UART_PUTS

	ldx	#$ABCD
	ldaa	#$12
	ldab	#$34

	xgdx

	stx	$80
	std	$82


	ldaa	$80
	jsr	F_UART_OUTHEX
	ldaa	$81
	jsr	F_UART_OUTHEX

	ldx	#crlf
	jsr	F_UART_PUTS

	ldaa	$82
	jsr	F_UART_OUTHEX
	ldaa	$83
	jsr	F_UART_OUTHEX

	ldx	#crlf
	jsr	F_UART_PUTS

	jmp	F_RESET

hello	db	$0a, $0d, 'Hello World!!!', $0a, $0d, 0
hello1	db	'Noting!', $0a, $0d, 0
crlf	db	$0a, $0d, 0
