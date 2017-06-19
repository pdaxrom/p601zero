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
	tsta
	bne	exit

	staa	LED_HEX

	ldx	#read_sec
	jsr	sd_read

	swi

	ldx	#read_sec2
	jsr	sd_read

	swi

	ldx	#write_sec
	jsr	sd_write

	swi

	ldx	#write_sec2
	jsr	sd_write

	swi

	jsr	sd_flush

	swi

exit	ldx	#bye
	jsr	F_UART_PUTS

	jmp	F_RESET

read_sec db	$00,$00,$00,$00
	dw	read_buf
read_sec2 db	$00,$00,$00,$01
	dw	read_buf2

write_sec db	$00,$00,$00,$01
	dw	read_buf
write_sec2 db	$00,$00,$00,$00
	dw	read_buf2

read_buf  equ $400
read_buf2 equ $600


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
	ldaa	#40
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
	bra	sd_disable
	endp

sd_command proc
	bsr	sd_disable
	bsr	sd_enable

	ldaa	0,x		; cmd
	jsr	spi_write
	ldaa	1,x		; arg
	jsr	spi_write
	ldaa	2,x		; arg
	jsr	spi_write
	ldaa	3,x		; arg
	jsr	spi_write
	ldaa	4,x		; arg
	jsr	spi_write
	ldaa	5,x		; CRC
	jsr	spi_write

	pshb
	ldab	#10
loop	jsr	spi_read
	cmpa	#$FF
	bne	exit
	decb
	bne	loop
exit	pulb
	rts
	endp

sd_enable proc
	pshx
	ldaa	SPI_EXTREG
	anda	#($FF^SPI_EXTSD)
	staa	SPI_EXTREG
	jsr	spi_read
	ldx	#5000
loop	jsr	spi_read
	cmpa	#$FF
	beq	exit
	jsr	sd_delay
	dex
	bne	loop
	bsr	sd_disable
	ldaa	#0
exit	inca
	pulx
	rts
	endp

sd_disable proc
	psha
	ldaa	SPI_EXTREG
	oraa	#SPI_EXTSD
	staa	SPI_EXTREG
	bsr	spi_read
	pula
	rts
	endp

;
; read sector from SD
;
; A = 0 - No error
;
; X - ptr to structure:
; ds 4 - sector
; ds 2 - buffer ptr
;
sd_read proc
	pshx
	pshb

;
; sector * 512
;
	ldaa	#$FF
	psha
	clra
	psha
	ldaa	3,x
	rola
	psha
	ldaa	2,x
	rola
	psha
	ldaa	1,x
	rola
	psha
	ldaa	#$51		; CMD17
	psha
	ldx	4,x		; buffer
	pshx
	tsx
	inx
	inx			; X to saved data for sd_command
	jsr	show_cmd
	pulx

	tsta
	beq	next
	ldaa	#1
	bra	exit

next	ldab	#255
next1	bsr	spi_read
	cmpa	#$FF
	bne	next2
	jsr	sd_delay
	decb
	bne	next1
	ldaa	#2
	bra	exit
next2	cmpa	#$FE
	beq	next3
	ldaa	#3
	bra	exit
next3	bsr	rcvr
	bsr	rcvr
	bsr	spi_read
	bsr	spi_read
	ldaa	#0

exit	tsx
	ldab	#6
	abx
	txs
	bsr	sd_disable

	pulb
	pulx
	rts

rcvr	ldab	#0
rcvr1	bsr	spi_read
	staa	0,x
	inx
	decb
	bne	rcvr1
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

;
; write sector to SD
;
; A = 0 - No error
;
; X - ptr to structure:
; ds 4 - sector
; ds 2 - buffer ptr
;
sd_write proc
	pshx
	pshb

;
; sector * 512
;
	ldaa	#$FF
	psha
	clra
	psha
	ldaa	3,x
	rola
	psha
	ldaa	2,x
	rola
	psha
	ldaa	1,x
	rola
	psha
	ldaa	#$58		; CMD24
	psha
	ldx	4,x		; buffer
	pshx
	tsx
	inx
	inx			; X to saved data for sd_command
	jsr	show_cmd
	pulx

	tsta
	beq	next
	ldaa	#1
	bra	exit

next	ldab	#255
next1	bsr	spi_read
	cmpa	#$FF
	beq	next2
	jsr	sd_delay
	decb
	bne	next1
	ldaa	#2
	bra	exit
next2	ldaa	#$FE
	bsr	spi_write
	bsr	xmit
	bsr	xmit
	bsr	spi_read
	bsr	spi_read
	bsr	spi_read
	anda	#$1F
	cmpa	#$05
	bne	next3
	ldaa	#0
	bra	exit
next3	ldaa	#3

exit	tsx
	ldab	#6
	abx
	txs
	jsr	sd_disable

	pulb
	pulx
	rts

xmit	ldab	#0
xmit1	ldaa	0,x
	bsr	spi_write
	inx
	decb
	bne	xmit1
	rts
	endp

sd_flush proc
	jsr	sd_enable
	tsta
	bne	exit
	jsr	sd_disable
exit	rts
	endp

hello	db	$0a, $0d, 'SD Card test!', $0a, $0d, 0
bye	db	$0a, $0d, 'Bye!', $0a, $0d, 0
