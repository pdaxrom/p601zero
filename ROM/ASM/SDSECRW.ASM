	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	int	F_PUTSTR


;	ldaa	#$10
;	ldab	#$20
;	ldx	#$BABE
;	int F_BPT

	jsr	sd_init

	int F_BPT

	tsta
	bne	exit

	ldx	#read_sec
	jsr	sd_read

	int F_BPT

	ldx	#read_sec2
	jsr	sd_read

	int F_BPT

	ldx	#write_sec
	jsr	sd_write

	int F_BPT

	ldx	#write_sec2
	jsr	sd_write

	int F_BPT

	jsr	sd_flush

	int F_BPT

exit	ldx	#bye
	int	F_PUTSTR

	int	F_WARMRES

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
loop1	jsr	sd_command
	cmpa	#$01
	beq	init2
	bsr	sd_delay
	decb
	bne	loop1
	ldaa	#1
	bra	exit

init2	ldx	#sd_init_cmd1
	ldab	#255
loop2	jsr	sd_command
	tsta
	beq	init3
	bsr	sd_delay
	decb
	bne	loop2
	ldaa	#2
	bra	exit

init3	ldx	#sd_init_cmd16
	jsr	sd_command
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

xsd_enable proc
	pshx
	ldaa	SPI_REG
	anda	#($FF^SPI_SD)
	staa	SPI_REG
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

sd_enable proc
	pshx
	pshb
	ldab	#1
wait	ldaa	#SPI_SD
	jsr	spi_select
	tsta
	bne	wait
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
	pulb
	pulx
	rts
	endp

sd_disable proc
	psha
	pshb
	ldaa	#SPI_SD
	ldab	#0
	jsr	spi_select
	jsr	spi_read
	pulb
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
	jsr	sd_command
	pulx

	tsta
	beq	next
	ldaa	#1
	bra	exit

next	ldab	#255
next1	jsr	spi_read
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
	jsr	spi_read
	jsr	spi_read
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
rcvr1	jsr	spi_read
	staa	0,x
	inx
	decb
	bne	rcvr1
	rts
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
	jsr	sd_command
	pulx

	tsta
	beq	next
	ldaa	#1
	bra	exit

next	ldab	#255
next1	jsr	spi_read
	cmpa	#$FF
	beq	next2
	jsr	sd_delay
	decb
	bne	next1
	ldaa	#2
	bra	exit
next2	ldaa	#$FE
	jsr	spi_write
	bsr	xmit
	bsr	xmit
	jsr	spi_read
	jsr	spi_read
	jsr	spi_read
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
	jsr	spi_write
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

; Check if spi in use
; Return:
; A 0 - not used, 1 - busy
;
spi_getstat proc
	pshx
	eora	#SPI_ALL
	psha
	anda	SPI_REG
	tsx
	cmpa	0,x
	pula
	beq	okay
	ldaa	#1
	bra	exit
okay	clra
exit	pulx
	rts
	endp

; Select spi device
; A Device
; B 1 Enable / 0 Disable
; Return:
; A status (0 - okay, 1 - busy)

spi_select proc
	psha
	bsr	spi_getstat
	tsta
	pula
	beq	select
	ldaa	#1
	rts
select	tstb
	beq	disable
	eora	#$FF
	anda	SPI_REG
	staa	SPI_REG
	bra	okay
disable	oraa	SPI_REG
	staa	SPI_REG
okay	clra
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

hello	db	$0a, $0d, 'SD Card test!', $0a, $0d, 0
bye	db	$0a, $0d, 'Bye!', $0a, $0d, 0
