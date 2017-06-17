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

loop	jsr	F_UART_IN
	staa	LED_HEX
	jsr	F_UART_OUT
	cmpa	#27
	bne	loop

	ldx	#bye
	jsr	F_UART_PUTS
	jmp	F_RESET

hello	db	$0a, $0d, 'Hello World!!!', $0a, $0d, 0
bye	db	$0a, $0d, 'Bye!!!', $0a, $0d, 0
