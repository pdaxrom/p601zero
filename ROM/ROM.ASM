;
; BOOTROM for Z/pdaXrom
; (c) sashz <sashz@pdaXrom.org>, 2017
;

	include DEVMAP.INC

;
; BootROM variables and functions
;

	include BOOTROM.INC

END_ADDR	equ	$F0

BOOTROM_BASE	equ	$F800

BROM_STACK	equ	FBTEXT-1

FBTEXT		equ	$F558-40*27

		section $F558
QUEUEPTR	ds	2
QUEUELEN	ds	1
QUEUEBUF	ds	3
		ds	2

SCRADDR		ds	2
SCRSZX		ds	1
SCRSZY		ds	1
SCRXADJ		ds	1
SCRYADJ		ds	1
SCRMASK		ds	1
SCRBITS		ds	1
SCRMODE		ds	1
SCRATTR		ds	1
CURX		ds	1
CURY		ds	1
CURPTR		ds	2
CURMODE 	ds	1
		ds	1	; align

		ds	4	; align
VECIRQP		ds	1
VECSWIP		ds	1
VECNMIP		ds	1
VECRESP		ds	1
VECIRQ		ds	2
VECSWI		ds	2
VECNMI		ds	2
VECRES		ds	2

BROM_SWIPAG	ds	$80
BROM_SWIVEC	ds	$200
		ends

	org	BOOTROM_BASE

reset	sei

	ldaa	RAMPAGE_CTL
	oraa	#BRAM_DISABLE
	staa	RAMPAGE_CTL

; SRAM chip initialization
	ldaa	#0
sramini	ldx	#$A55A
	stx	$0
	ldx	$0
	cpx	#$A55A
	bne	sramin1
	ldab	IO_SWKEYS
	bitb	#1
	beq	sramok
	bra	onbrom
sramin1	inca
	bne	sramini

onbrom	ldab	RAMPAGE_CTL
	andb	#($FF^BRAM_DISABLE)
	stab	RAMPAGE_CTL
	ldab	#$1C
	stab	IO_L7HI
sramok	staa	$2
	staa	IO_L8BIT

; setup stubs
	ldx	#0
	stx	VECIRQP
	stx	VECNMIP

	ldx	#vstub_irq
	stx	VECIRQ
	ldx	#vstub_nmi
	stx	VECNMI
	ldx	#swihndl
	stx	VECSWI

; setup syscalls

	ldx	#BROM_SWIPAG
clrswipag clr	0,x
	inx
	cpx	#BROM_SWIPAG+$280
	bne	clrswipag

	lds	#romvecbeg
	des
	ldx	#BROM_SWIVEC+$C0*2
copyswiv pula
	staa	0,x
	inx
	cpx	#BROM_SWIVEC+$C0*2+(romvecend-romvecbeg)
	bne	copyswiv

	lds	#pylvecbeg
	des
copyswip pulb
	tstb
	beq	warmres
	ldx	#BROM_SWIVEC
	abx
	abx
	pula
	pulb
	std	0,x
	bra	copyswip

warmres	lds	#BROM_STACK

; reset spi/EXT devices
	jsr	spi_reset

; init putchar queue for control sequences
	clr	QUEUELEN
	ldx	#QUEUEBUF
	stx	QUEUEPTR

	ldaa	#$80
	ldx	#FBTEXT
	jsr	setvideomode

	ldx	#pylogo
	jsr	putstr

; setup prescaler: 24MHz / (Baud * 8)
	ldx	#26
	stx	UART_PRESCALER

; disable UART interrupts (clear UART_TIE and UART_RIE)
	clra
	staa	UART_CONFIG

	ldx	#pylogo
	jsr	uart_puts

	ldaa	RAMPAGE_CTL
	bita	#BRAM_DISABLE
	beq	bramen
	ldx	#txt_extram
	bra	ramtxt
bramen	ldx	#txt_bram
ramtxt	bsr	uart_puts
	jsr	putstr

;
; Trying to boot from SD
;
	jsr	sd_init
	tsta
	bne	no_sd_boot

	ldx	#boot_sec
	jsr	sd_read
	tsta
	bne	no_sd_boot
	ldx	$2FE
	cpx	#$55AA
	bne	no_sd_boot
	jsr	$13E

no_sd_boot

loop
	bsr	uart_in
	cmpa	#'L'
	beq	cmd_load
	cmpa	#'S'
	beq	cmd_save
	cmpa	#'G'
	beq	cmd_go
	ldaa	#'E'
	bsr	uart_out
	bra	loop

cmd_load
	bsr	get_block_addr
cmd_lo1	bsr	uart_in
	staa	0,x
	inx
	cpx	END_ADDR
	bne	cmd_lo1
cmd_oka	ldaa	#'O'
	bsr	uart_out
	bra	loop

cmd_save
	bsr	get_block_addr
cmd_sa1	ldaa	0,x
	bsr	uart_out
	inx
	cpx	END_ADDR
	bne	cmd_sa1
	bra	cmd_oka

cmd_go
	bsr	get_word
	jsr	0,x
	jmp	warmres

get_block_addr proc
	bsr	get_word
	pshx
	bsr	get_word
	stx	END_ADDR
	pulx
	rts
	endp

;; UART IN/OUT

uart_in proc
	ldaa	UART_STATUS
	bita	#UART_RRD
	beq	uart_in
	ldaa	UART_DATA
	rts
	endp

uart_out proc
	pshb
loop	ldab	UART_STATUS
	bitb	#UART_TRD
	beq	loop
	staa	UART_DATA
	pulb
	rts
	endp

uart_puts proc
	pshx
	psha
loop	ldaa	0,x
	tsta
	beq	exit
	bsr	uart_out
	inx
	bra	loop
exit	pula
	pulx
	rts
	endp

uart_outhex proc
	psha
	pshb
	tab
	bsr	OUTNIBH
	tba
	bsr	OUTNIBL
	pulb
	pula
	rts
OUTNIBH	lsra
	lsra
	lsra
	lsra
OUTNIBL	anda	#$0F
	oraa	#$30
	cmpa	#$39
	bls	OUTNIBX
	adda	#$7
OUTNIBX bsr	uart_out
	rts
	endp

get_word proc
	bsr	uart_in
	tab
	bsr	uart_in
	psha
	pshb
	pulx
	rts
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Set video mode
; A = $00 - text, $03 - graphics,
; X = Video address
;

setvideomode proc
	pshx
	pshb
	psha
	stx	SCRADDR
	stab	SCRATTR
	tab
	anda	#$7F
	staa	SCRMODE
	ldx	txtmode
	stx	SCRSZX
	ldx	txtmode+2
	stx	SCRXADJ
	ldx	txtmode+4
	stx	SCRMASK
	cmpa	#0
	bne	mode3
	inc	SCRSZY		; 27 text rows
	inc	SCRSZY		;
	bitb	#$80
	beq	next
	ldaa	SCRSZY
	bra	clrs
mode3	cmpa	#3
	bne	exit
	ldaa	#VPU_GRF
	staa	SCRBITS
	bitb	#$80
	beq	next
	ldaa	SCRSZY
	lsla
	lsla
	lsla
clrs	jsr	clrscry
	clr	CURX
	clr	CURY
next	ldx	#SCRADDR
	bsr	vpuconfig
	ldaa	CURX
	ldaa	CURY
	bsr	setcursor
exit	pula
	pulb
	pulx
	rts

txtmode	db	40, 25, 11, 60, $FF^VPU_GRF, 0
	endp

; Configure VPU
; X = ptr
;
; ptr dw vaddr  ; 0
;     db width  ; 2
;     db height ; 3
;     db hadj   ; 4
;     db vadj   ; 5
;     db mask   ; 6
;     db bits   ; 7
;

vpuconfig proc
	pshb
	psha

; Set framebuffer address
	ldd	0,x
	std	VPU_VADDR

; Set start line
	clra
	ldab	5,x
	std	VPU_VSTART

; Set end line
	clra
	ldab	3,x
	lsld
	lsld
	lsld
	addd	VPU_VSTART
	std	VPU_VEND

; Framebuffer horisontal position
	ldaa	4,x
	staa	VPU_HSTART

; Start dma engine
	ldaa	2,x
	staa	VPU_HSIZE

; Set bits
	ldaa	#VPU_GRF
	anda	6,x
	oraa	7,x
	staa	VPU_CFG

	pula
	pulb
	rts
	endp

; Get video mode
; Return
; X - address
; A - mode
; B - attributes

getvideomode proc
	ldaa	SCRMODE
	ldab	SCRATTR
	ldx	SCRADDR
	rts
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Set VPU cursor
; A - column
; B - row
;

vpucursor proc
	pshx
	pshb
	psha
	adda	#11
	inca
	staa	VPU_CPOS
	clra
	lsld
	lsld
	lsld
	ldx	#60
	pshx
	tsx
	addd	0,x
	pulx
	std	VPU_CSTART
	addd	#7
	std	VPU_CEND

	ldaa	VPU_CFG
	oraa	#VPU_CEN
	oraa	#VPU_CIN
;	anda	#($FF ^ VPU_CIN)
	staa	VPU_CFG

	pula
	pulb
	pulx
	rts
	endp

setcursor proc
	cmpa	SCRSZX
	bcc	exit
	cmpb	SCRSZY
	bcc	exit
	pshb
	psha
	staa	CURX
	stab	CURY
	bsr	vpucursor
	ldaa	SCRSZX
	mul
	std	CURPTR
	clra
	ldab	CURX
	addd	CURPTR
	addd	SCRADDR
	std	CURPTR
	pula
	pulb
exit	rts
	endp

getcursor proc
	ldaa	CURX
	ldab	CURY
	ldx	CURPTR
	rts
	endp

putchar	proc
	pshx
	pshb
	psha

	ldab	SCRMODE
	andb	#$03
	bne	return1		; graf mode not supported

	tst	QUEUELEN
	beq	putch0
queue1	ldx	QUEUEPTR
	staa	0,x
	inx
	stx	QUEUEPTR
	dec	QUEUELEN
	bne	return1
	ldx	#QUEUEBUF
	stx	QUEUEPTR
	ldaa	0,x
	cmpa	#$1E
	bne	queue1b
	ldaa	1,x
	suba	#$20
	ldab	2,x
	subb	#$20
	bsr	setcursor
	bra	return1
queue1b	cmpa	#$1B
	bne	return1
	ldaa	1,x
	bra	putnorm

return1	pula
	pulb
	pulx
	rts

putch0	cmpa	#$1B
	bne	putc1e
	ldab	#2
queueup	stab	QUEUELEN
	bra	queue1
putc1e	cmpa	#$1E
	bne	putc08
	ldab	#3
	bra	queueup
putc08	cmpa	#$08
	bne	putc09
	ldaa	CURX
	deca
	ldab	CURY
	bra	setcur
putc09	cmpa	#$09
	bne	putc0a
	ldaa	CURX
	adda	#8
	anda	#%11111000
	ldab	CURY
	bra	setcur
putc0a	cmpa	#$0A
	bne	putch0c
	ldaa	CURX
	ldab	CURY
	incb
	cmpb	SCRSZY
	bne	setcur
	bsr	scroll
	bra	return1
putch0c	cmpa	#$0C
	bne	putch0d
	bsr	clrscr
	clra
	clrb
	bra	setcur
putch0d	cmpa	#$0D
	bne	putch18
	clra
	ldab	CURY
	bra	setcur
putch18	cmpa	#$18
	bne	putch7f
	bsr	clr2eol
	bra	return1
putch7f	cmpa	#$7F
	bne	putnorm
	ldaa	CURX
	beq	return1
	deca
	ldx	CURPTR
	dex
	clr	0,x
	ldab	CURY
	bra	setcur
putnorm	ldx	CURPTR
	staa	0,x
	ldaa	CURX
	ldab	CURY
	inca
setcur	jsr	setcursor
	jmp	return1
	endp

clrscr	proc
	global	clrscry, clr2eol
	ldaa	SCRSZY
clrscry	ldab	SCRSZX
	mul
	ldx	SCRADDR
clrs1	clr	0,x
	inx
	subd	#1
	bne	clrs1
	rts

clr2eol	ldx	CURPTR
	ldaa	SCRSZY
	suba	CURX
eoloop	clr	0,x
	inx
	deca
	bne	eoloop
	rts
	endp

scroll	proc
	ldx	SCRADDR
	ldab	SCRSZX
	abx
	ldaa	SCRSZY
	deca
	mul

	db	$18, $3C	;	pshy
	db	$18, $FE	;	ldy	SCRADDR
	dw	SCRADDR
loop	psha
	ldaa	0,x
	db	$18, $A7, $00	;	staa	0,y
	inx
	db	$18, $08	;	iny
	pula
	subd	#1
	bne	loop
	ldaa	SCRSZX
loop1	db	$18, $6F, $00	;	clr	0,y
	db	$18, $08	;	iny
	deca
	bne	loop1
	db	$18, $38	;	puly

	rts
	endp

putstr	proc
	pshx
	psha
loop	ldaa	0,x
	beq	ret
	jsr	putchar
	inx
	bra	loop
ret	pula
	pulx
	rts
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Reset SPI/EXT devices
spi_reset proc
	psha
	ldaa	#SPI_INI
	oraa	SPI_REG
	staa	SPI_REG

	ldaa	SPI_REG
	anda	#($FF^SPI_RES)
	staa	SPI_REG

	ldaa	SPI_REG
	oraa	#SPI_RES
	staa	SPI_REG
	pula
	rts
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
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
	pshb
	psha
	ldaa	#SPI_SD
	ldab	#0
	jsr	spi_select
	jsr	spi_read
	pula
	pulb
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Write to PSG
; A - Address reg
; B - Data
;
psg_send proc
	global psg_write
	psha
	bsr	spi_send
	bsr	bc1off
	tba
	bsr	spi_send
	bsr	bc1on
	tab
	pula
	rts

psg_write pshx
	pshb
	psha
	tab
	clra
loop	bsr	spi_send
	bsr	bc1off
	psha
	ldaa	0,x
	bsr	spi_send
	bsr	bc1on
	pula
	inx
	inca
	decb
	bne	loop
	pula
	pulb
	pulx
	rts

spi_send pshb
	staa	SPI_DATA
busy	ldab	SPI_STATUS
	bitb	#SPI_READY
	beq	busy
	pulb
	rts

bc1off	psha
	ldaa	SPI_REG
	anda	#($FF^SPI_PSGBC1)
	staa	SPI_REG
	pula
	rts

bc1on	psha
	ldaa	SPI_REG
	oraa	#SPI_PSGBC1
	staa	SPI_REG
	pula
	rts
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
umult	proc
P	equ	0
Q	equ	2
R	equ	4
	pshx		; R
	pshx		; R
	pshx		; Q
	pshb		; P
	psha		; P
	tsx

	clrb
	clra
	std	R,x
	ldaa	P+1,x
	ldab	Q+1,x
	mul
	std	R+2,x
	ldaa	P,x
	ldab	Q+1,x
	mul
	addd	R+1,x
	std	R+1,x
	bcc	MUL002
	inc	R,x
MUL002	ldaa	P+1,x
	ldab	Q,x
	mul
	addd	R+1,x
	std	R+1,x
	bcc	MUL004
	inc	R,x
MUL004	ldaa	P,x
	ldab	Q,x
	mul
	addd	R,x
;	std	R,x
;	ldx	R+2,x
	pulx
	pulx
	pulx
	pulx
	xgdx
	rts
	endp

udiv	proc
DIV	equ	3
QUO	equ	1
KT	equ	0

	pshb		; divisor
	psha		;
	pshx		; dividend
	ldab	#1
	pshb		; counter
	tsx

	ldd	DIV,x
	beq	error
	bmi	DIV002
DIV001	inc	KT,x
	asld
	bpl	DIV001
	std	DIV,x
DIV002	ldd	QUO,x
	clr	QUO,x
	clr	QUO+1,x
DIV003	subd	DIV,x
	bcc	DIV004
	addd	DIV,x
	clc
	bra	DIV005
DIV004	sec
DIV005	rol	QUO+1,x
	rol	QUO,x
	lsr	DIV,x
	ror	DIV+1,x
	dec	KT,x
	bne	DIV003

	pshb
	psha
	ldd	QUO,x
	pulx

	clc
	bra	okay
error	sec
okay	ins
	ins
	ins
	ins
	ins
	rts
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
swihndl proc
	sei
	tsx
	ldd	7,x
	addd	#1
	std	7,x
	xgdx
	dex
	ldaa	0,x

	ldab	RAMPAGE_SEL
	pshb
	tab
	ldx	#BROM_SWIPAG
	lsrb
	abx
	ldab	0,x
	bcc	swih1
	lsrb
	lsrb
	lsrb
	lsrb
swih1	andb	#$0F
	beq	swih2
	stab	RAMPAGE_SEL

swih2	tab
	ldx	#BROM_SWIVEC
	abx
	abx
	ldx	0,x
	cpx	#0
	beq	exit
	xgdx
	ldx	#swiret
	pshx
	pshb
	psha

	tsx
	ldab	6,x
	ldaa	7,x
	psha
	ldaa	5,x
;	db	$1a		; ldy prefix
;	ldx	10,x		; ldy 10,x
	ldx	8,x
	tap
	pula
	rts

swiret	sei
	pshx
	tsx
	stab	4,x
	staa	5,x
	pula
	staa	6,x
	pula
	staa	7,x
	db	$1a		; sty prefix
	stx	8,x		; sty 8,x
exit	pulb
	stab	RAMPAGE_SEL
	rti
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
bpt	proc
	db	$18		; pshy prefix
	pshx			; pshy
	pshb
	psha
	pshx
	tpa
	psha
	ldx	#regstxt
	jsr	uart_puts
	tsx
	ldaa	0,x
	bsr	regshex
	ldaa	3,x
	bsr	regshex
	ldaa	4,x
	bsr	regshex
	ldaa	1,x
	bsr	regshex
	ldaa	2,x
	bsr	regshex
	ldaa	5,x
	bsr	regshex
	ldaa	6,x
	bsr	regshex
	tsx
	xgdx
	addd	#$12
	xgdx
	dex
	ldd	0,x
	inx
	xgdx
	pshx
	bsr	regshex
	tba
	bsr	regshex
	pula
	bsr	regshex
	pula
	bsr	regshex
	ldx	#regsnl
	jsr	uart_puts
	pula
	tap
	pulx
	pula
	pulb
	db	$18		; puly prefix
	pulx			; puly
	rts
regshex	jmp	uart_outhex

regstxt	db	10, 13, 'P_A_B_X___Y___SP__PC__', 10, 13, 0
regsnl	db	10, 13, 0
	endp

;
;----
inthandlers proc
	global vstub_irq, vstub_swi, vstub_nmi
vstub_irq
	ldx	#vectextIRQ
	bra	ret

vstub_swi
	ldx	#vectextSWI
	bra	ret

vstub_nmi
	ldx	#vectextNMI
ret	jsr	uart_puts
	rti
	endp

vectextIRQ	db	'IRQ',0
vectextSWI	db	'SWI',0
vectextNMI	db	'NMI',0

;----
intvectors proc
	global vec_irq, vec_swi, vec_nmi
vec_irq	ldab	VECIRQP
	ldx	VECIRQ
callvec	ldaa	RAMPAGE_SEL
	psha
	stab	RAMPAGE_SEL
	cpx	#0
	beq	exit
	jsr	0,x
exit	pula
	staa	RAMPAGE_SEL
	rti

vec_swi	ldx	VECSWI
	jmp	0,x

vec_nmi	ldab	VECNMIP
	ldx	VECNMI
	bra	callvec
	endp

pylvecbeg
	db	$12
	dw	setvideomode
	db	$13
	dw	getvideomode
	db	$14
	dw	getcursor
	db	$15
	dw	setcursor
	db	$22
	dw	putchar
	db	$23
	dw	putstr
pylvecend
	db	0

romvecbeg
	dw	reset
	dw	warmres
	dw	uart_in
	dw	uart_out
	dw	uart_puts
	dw	uart_outhex
	dw	vpuconfig
	dw	vpucursor
	dw	spi_reset
	dw	spi_getstat
	dw	spi_select
	dw	spi_write
	dw	spi_read
	dw	sd_init
	dw	sd_read
	dw	sd_write
	dw	sd_flush
	dw	psg_send
	dw	psg_write
	dw	umult
	dw	udiv
	dw	bpt
romvecend

boot_sec db	$00,$00,$00,$00
	dw	$100

pylogo		db	'Z/pdaXrom', 10, 13, 0
;		db	'(c) sashz <sash@pdaXrom.org>, 1997-2017', 10, 13, 0
txt_bram	db	'Use internal RAM.', 10, 13, 0
txt_extram	db	'Use external RAM.', 10, 13, 0

	ds	$fff8-*, $ff
	dw	vec_irq
	dw	vec_swi
	dw	vec_nmi
	dw	reset
