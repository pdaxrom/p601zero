	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	jsr	F_UART_PUTS

	ldaa	#5
	staa	SPI_PRESCALER

	jsr	bc1on

	jsr	psg_reset

loop	ldx	#buf
read	jsr	F_UART_IN
	staa	0,x
	inx
	cpx	#buf+16
	bne	read

	ldx	#buf
	ldaa	#0

	ldab	0,x
	bsr	psg_write
	inca
	ldab	1,x
	bsr	psg_write
	inca
	ldab	2,x
	bsr	psg_write
	inca
	ldab	3,x
	bsr	psg_write
	inca
	ldab	4,x
	bsr	psg_write
	inca
	ldab	5,x
	bsr	psg_write
	inca
	ldab	6,x
	bsr	psg_write
	inca
	ldab	7,x
	bsr	psg_write
	inca
	ldab	8,x
	bsr	psg_write
	inca
	ldab	9,x
	bsr	psg_write
	inca
	ldab	10,x
	bsr	psg_write
	inca
	ldab	11,x
	bsr	psg_write
	inca
	ldab	12,x
	bsr	psg_write
	inca
	ldab	13,x
	bsr	psg_write
	inca

;	ldaa	#15
;	ldab	#0
;	bsr	psg_write	; empty write

	ldaa	INPUT_SWKEYS
	bita	#1
	beq	loop

exit	bsr	psg_reset
	ldx	#bye
	jsr	F_UART_PUTS
	jmp	F_RESET

psg_reset proc
;	reset ext devices
	ldaa	SPI_EXTREG
	anda	#($FF^SPI_EXTRES)
	staa	SPI_EXTREG

	ldaa	SPI_EXTREG
	oraa	#SPI_EXTRES
	staa	SPI_EXTREG
	rts
	endp

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

hello	db	$0a, $0d, 'AY-3-8912 CHIPTUNE!', $0a, $0d, 0
bye	db	$0a, $0d, 'Bye!', $0a, $0d, 0

buf	ds	16
