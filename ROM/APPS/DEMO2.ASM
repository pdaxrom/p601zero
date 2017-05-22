	include ../DEVMAP.INC

	include ../BOOTROM.INC

	section $0020
m1	ds	1
m2	ds	2
m3	ds	1
m4	ds	2
	ends

	org $100

	ldx	#hello
	jsr	F_UART_PUTS

	ldaa	#$03
	staa	$e600
	ldaa	#$20
	staa	$e601

	ldaa	#$04
	staa	$e600
	ldaa	#$26
	staa	$e601

	ldaa	#$03
	staa	$e600

	ldaa	m1
	ldx	m2
	staa	m3
	stx	m4

	ldaa	$e600
	jsr	F_UART_OUTHEX
	ldaa	#32
	jsr	F_UART_OUT
	ldaa	$e601
	jsr	F_UART_OUTHEX

	jmp	F_RESET

hello	db	$0a, $0d, 'Hello World!!!', $0a, $0d, 0
