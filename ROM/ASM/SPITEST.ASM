	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	int	F_UART_PUTS

	ldaa	#5
	staa	SPI_PRESCALER

	ldaa	#$FF
	staa	SPI_REG

	ldaa	SPI_STATUS
	int	F_UART_OUTHEX

send	int	F_UART_IN
	cmpa	#27
	beq	exit
	int	F_UART_OUTHEX

;send1	ldaa	#$aa
	staa	SPI_DATA
busy	ldab	SPI_STATUS
	bitb	#SPI_READY
	beq	busy
	ldaa	SPI_DATA
; bra send1
	int	F_UART_OUTHEX
	bra	send

exit	ldx	#bye
	int	F_UART_PUTS
	int	F_WARMRES

hello	db	$0a, $0d, 'SPI test!', $0a, $0d, 0
bye	db	$0a, $0d, 'Bye!', $0a, $0d, 0
