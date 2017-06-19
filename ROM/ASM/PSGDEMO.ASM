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

;	reset ext devices
	ldaa	SPI_EXTREG
	anda	#($FF^SPI_EXTRES)
	staa	SPI_EXTREG

	ldaa	SPI_EXTREG
	oraa	#SPI_EXTRES
	staa	SPI_EXTREG

; Configure port A for output
;	ldaa	#7
;	ldab	#$C0
;	bsr	psg_write

; write to port A
;	ldaa	#14
;	ldab	#$AA
;	bsr	psg_write

;
	ldaa	#7
	ldab	#($38 | $C0)
	bsr	psg_write

	ldaa	#0
	ldab	#100
	bsr	psg_write

	ldaa	#1
	ldab	#3
	bsr	psg_write

	ldaa	#2
	ldab	#100
	bsr	psg_write

	ldaa	#3
	ldab	#3
	bsr	psg_write

	ldaa	#4
	ldab	#200
	bsr	psg_write

	ldaa	#5
	ldab	#3
	bsr	psg_write

	ldaa	#8
	ldab	#15
	bsr	psg_write

	ldaa	#9
	ldab	#15
	bsr	psg_write

	ldaa	#10
	ldab	#15
	bsr	psg_write

;;
;	ldaa	#14
;	ldab	#$AA
;	bsr	psg_write
;;

;cycle	bsr	spi_send
;	bra	cycle
;;

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
	ldaa	SPI_EXTREG
	anda	#($FF^SPI_EXTPSGBC1)
	staa	SPI_EXTREG
	pula
	rts
	endp

bc1on	proc
	psha
	ldaa	SPI_EXTREG
	oraa	#SPI_EXTPSGBC1
	staa	SPI_EXTREG
	pula
	rts
	endp

hello	db	$0a, $0d, 'PSG test!', $0a, $0d, 0
bye	db	$0a, $0d, 'Bye!', $0a, $0d, 0
