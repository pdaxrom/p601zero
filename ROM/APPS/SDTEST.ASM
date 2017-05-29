	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	jsr	F_UART_PUTS


;	ldaa	#$10
;	ldab	#$20
;	ldx	#$BABE
;	swi

	jsr	sd_init

	staa	LED_HEX

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
	jsr	sd_command
	jsr	F_UART_OUTHEX
	rts
	endp

txtcmd	db	10, 13, 'CMD ', 0

sd_delay proc
	pshx
	ldx	#4000
loop	dex
	bne	loop
	pulx
	rts
	endp

sd_init_cmd0	db	$40, $00, $00, $00, $00, $95
sd_init_cmd1	db	$41, $00, $00, $00, $00, $FF
sd_init_cmd16	db	$50, $00, $00, $02, $00, $FF

sd_init	proc
	pshb
	pshx
	ldaa	#5
	staa	SPI_PRESCALER
	jsr	sd_disable
	ldab	#10
loop	jsr	spi_read
	decb
	bne	loop

	ldx	#sd_init_cmd0
	ldab	#10
loop1	jsr	show_cmd
	cmpa	#$01
	beq	init2
	bsr	sd_delay
	decb
	bne	loop1
	ldaa	#1
	bra	exit

init2	ldx	#sd_init_cmd1
	ldab	#255
loop2	jsr	show_cmd
	tsta
	beq	init3
	bsr	sd_delay
	decb
	bne	loop2
	ldaa	#2
	bra	exit

init3	ldx	#sd_init_cmd16
	jsr	show_cmd
	clra
exit	pulx
	pulb
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

	pshb
	ldab	#10
loop	jsr	spi_read
	cmpa	#$FF
	bne	exit
	decb
	bne	loop
exit	pulb
	bra	sd_disable
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
	bsr	spi_read
	pula
	rts
	endp

spi_write proc
	global	spi_read
	staa	SPI_DATA
loop	ldaa	SPI_STATUS
	bita	#SPI_READY
	beq	loop
	ldaa	SPI_DATA
	rts
spi_read ldaa	#$FF
	bra	spi_write
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
