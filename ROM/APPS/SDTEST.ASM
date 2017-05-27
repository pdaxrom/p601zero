	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	jsr	F_UART_PUTS

	jsr	sd_init

mainloop jsr	F_UART_IN
	cmpa	#'1'
	bne	next1
	ldx	#cmd40
	bra	exec
next1	cmpa	#'2'
	bne	next2
	ldx	#cmd41
	bra	exec
next2	cmpa	#'3'
	bne	next3
	ldx	#cmd50
exec	bsr	show_cmd

	ldab	#8
	ldx	#buffer
dump	ldaa	0,x
	jsr	F_UART_OUTHEX
	ldaa	#' '
	jsr	F_UART_OUT
	inx
	decb
	bne	dump
	bra	mainloop

next3	cmpa	#'4'
	bne	next
;	ldx	#cmd51
;	bsr	sd_command

	


	bra	mainloop
next	cmpa	#27
	bne	mainloop

	ldx	#bye
	jsr	F_UART_PUTS
	jmp	F_RESET

show_cmd proc
	pshx
	ldx	#txtcmd
	jsr	F_UART_PUTS
	pulx
	ldaa	0,x
	jsr	F_UART_OUTHEX
	ldaa	#' '
	jsr	F_UART_OUT
	bra	sd_command
	endp

txtcmd	db	10, 13, 'CMD ', 0

cmd40	db	$40, 0, 0, 0, 0, $95
	dw	buffer
	dw	8

cmd41	db	$41, 0, 0, 0, 0, $FF
	dw	buffer
	dw	8

cmd50	db	$50, 0, 0, $02, 0, $FF
	dw	buffer
	dw	8

cmd51	db	$51, 0, 0, 0, 0, $FF
	dw	buffer
	dw	8

sd_init	proc
	ldaa	#5
	staa	SPI_PRESCALER
	bsr	sd_disable
	ldab	#10
loop	ldaa	#$FF
	bsr	spi_write
	decb
	bne	loop
	rts
	endp

sd_command proc
	bsr	sd_enable
	ldaa	0,x		; cmd
	bsr	spi_write
	ldaa	1,x		; arg
	bsr	spi_write
	ldaa	2,x		; arg
	bsr	spi_write
	ldaa	3,x		; arg
	bsr	spi_write
	ldaa	4,x		; arg
	bsr	spi_write
	ldaa	5,x		; CRC
	bsr	spi_write
	pshx
	ldx	6,x
	stx	$20
	pulx
	ldx	8,x
loop	cpx	#0
	beq	exit
	ldaa	#$FF
	bsr	spi_write
	pshx
	ldx	$20
	staa	0,x
	inx
	stx	$20
	pulx
	dex
	bra	loop
exit	bsr	sd_disable
	rts
	endp

sd_enable proc
	psha
	ldaa	SPI_STATUS
	anda	#($FF^SPI_SSN)
	staa	SPI_STATUS
	pula
	rts
	endp

sd_disable proc
	psha
	ldaa	SPI_STATUS
	oraa	#SPI_SSN
	staa	SPI_STATUS
	pula
	rts
	endp

spi_write proc
	staa	SPI_DATA
loop	ldaa	SPI_STATUS
	bita	#SPI_READY
	beq	loop
	ldaa	SPI_DATA
	rts
	endp

; read sector from SD
;
; X - ptr to structure:
; ds 4 - sector
; ds 2 - buffer ptr
;
sdreadsec proc
	psha

	pula
	rts
	endp

sec1	db	0, 0, 0, 0
	dw	$1000

hello	db	$0a, $0d, 'SD Card test!', $0a, $0d, 0
bye	db	$0a, $0d, 'Bye!', $0a, $0d, 0

buffer	ds	200
