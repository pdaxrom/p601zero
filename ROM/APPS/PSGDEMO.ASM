	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	jsr	F_UART_PUTS

	ldaa	#5
	staa	SPI_PRESCALER

	ldaa	SPI_STATUS
	staa	LED_HEX

	bsr	bc1on

	ldaa	#7
	ldab	#$C0
	bsr	psg_write

	ldaa	#14
	ldab	#$FD
	bsr	psg_write

exit	ldx	#bye
	jsr	F_UART_PUTS
	jmp	F_RESET

; Write to PSG
; A - Address reg
; B - Data
psg_write proc
	psha
	bsr	spi_send
	bsr	bc1off
	tba
	bsr	spi_send
	bsr	bc1on
	pula
	rts
	endp

spi_send proc
	pshb
	staa	SPI_DATA
busy	ldab	SPI_STATUS
	bitb	#SPI_READY
	beq	busy
	pulb
	rts
	endp

bc1off	proc
	psha
	ldaa	SPI_STATUS
	anda	#($FF^SPI_SSN)
	staa	SPI_STATUS
	pula
	rts
	endp

bc1on	proc
	psha
	ldaa	SPI_STATUS
	oraa	#SPI_SSN
	staa	SPI_STATUS
	pula
	rts
	endp

hello	db	$0a, $0d, 'PSG test!', $0a, $0d, 0
bye	db	$0a, $0d, 'Bye!', $0a, $0d, 0
