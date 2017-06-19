	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	jsr	F_UART_PUTS

	ldaa	#5
	staa	SPI_PRESCALER

	ldaa	#$FF
	staa	SPI_EXTREG

	ldaa	SPI_STATUS
	staa	LED_HEX

send	jsr	F_UART_IN
	cmpa	#27
	beq	exit
	jsr	F_UART_OUTHEX

;send1	ldaa	#$aa
	staa	SPI_DATA
busy	ldab	SPI_STATUS
	bitb	#SPI_READY
	beq	busy
	ldaa	SPI_DATA
; bra send1
	jsr	F_UART_OUTHEX
	bra	send

exit	ldx	#bye
	jsr	F_UART_PUTS
	jmp	F_RESET

hello	db	$0a, $0d, 'SPI test!', $0a, $0d, 0
bye	db	$0a, $0d, 'Bye!', $0a, $0d, 0
