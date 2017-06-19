;
; UART BOOTROM for BLACK EYES 601 Zero
; (c) sashz <sashz@pdaXrom.org>, 2017
;

	include DEVMAP.INC

	include BOOTROM.INC

	include BIOS/MEMORY.INC

;---------------
; RAM work area locations:
swihndl_x equ	2

	org	BOOTROM_BASE

	jmp	warmres
	jmp	uart_in
	jmp	uart_out
	jmp	uart_puts
	jmp	uart_outhex
	jmp	setvideomode
	jmp	spi_reset
	jmp	spi_getstat
	jmp	spi_select
	jmp	spi_write
	jmp	spi_read
	jmp	sd_init
	jmp	sd_read
	jmp	sd_write
	jmp	sd_flush
	jmp	psg_write

reset
	sei

; setup stubs
	ldx	#vstub_irq
	stx	VIRQ
	ldx	#vstub_swi
	stx	VSWI
	ldx	#vstub_nmi
	stx	VNMI

	ldaa	RAMPAGE_CTL
	oraa	#BRAM_DISABLE
	staa	RAMPAGE_CTL

	ldx	#$A55A
	stx	$f0
	ldx	$f0
	cpx	#$A55A
	beq	warmres

	ldaa	RAMPAGE_CTL
	anda	#($FF^BRAM_DISABLE)
	staa	RAMPAGE_CTL

warmres	lds	#$ef

; reset spi/EXT devices
	jsr	spi_reset

; setup prescaler: 24MHz / (Baud * 8)
	ldx	#26
	stx	UART_PRESCALER

; disable UART interrupts (clear UART_TIE and UART_RIE)
	clra
	staa	UART_CONFIG

	ldx	#pylogo
	bsr	uart_puts

	ldaa	RAMPAGE_CTL
	bita	#BRAM_DISABLE
	beq	bramen
	ldx	#txt_extram
	bra	ramtxt
bramen	ldx	#txt_bram
ramtxt	bsr	uart_puts

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
	bra	warmres

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
; A = 0 - text, 1 - graphics, $FF - disable video
; X = Video address
;
setvideomode proc
SCR_START	equ	VPU_UREG1
	pshx
	psha
	pshb
	tab

; Disable video interrupt
	ldaa	VPU_CFG
	anda	#($FF^VPU_IEN) ; $BF
	staa	VPU_CFG

	cmpb	#$FF
	beq	exit

	stx	SCR_START

	cmpb	#0
	bne	initgrf

	ldx	#videotxthndl

; Set text mode
	ldaa	VPU_CFG
	anda	#($FF^VPU_GRF); $DF
	staa	VPU_CFG

; Set char line address
	ldaa	#7
	staa	VPU_CLINE

	bra	next

initgrf	ldx	#videohndl

; Set graphics mode
	ldaa	VPU_CFG
	oraa	#VPU_GRF
	staa	VPU_CFG

; Set video interrupt handler
next	stx	VNMI

; Set start line
	ldx	#60
	stx	VPU_VSTART

; Set end line
	ldx	#260
	stx	VPU_VEND

; Set DMA step
	ldaa	#0
	staa	VPU_VSTEP
	psha
; Clear screen
	ldx	#0
	stx	VPU_ADDR
	tsx
	stx	VPU_VADDR
	pula

; let start DMA engine
	ldaa	#64
	staa	VPU_VSIZE

; Set DMA step
	ldaa	#1
	staa	VPU_VSTEP

; Framebuffer position
	ldx	#11
	stx	VPU_ADDR

; Enable video interrupts
	ldaa	VPU_CFG
	oraa	#VPU_IEN
	staa	VPU_CFG

exit	pulb
	pula
	pulx
	rts
	endp

videohndl proc
	sei
	ldaa	VPU_STAT
	bita	#VPU_IRQ
	beq	exit
	bita	#VPU_SVL
	beq	blank

; let start DMA engine
	ldaa	#40
	staa	VPU_VSIZE

exit	rti

blank	ldx	SCR_START
	stx	VPU_VADDR
	rti
	endp

videotxthndl proc
	sei
	ldaa	VPU_STAT
	bita	#VPU_IRQ
	beq	exit
	bita	#VPU_SVL
	beq	blank

	ldaa	VPU_CLINE
	inca
	anda	#$07
	staa	VPU_CLINE
	bne	exit

; let start DMA engine
	ldaa	#40
	staa	VPU_VSIZE

exit	rti

blank	ldx	SCR_START
	stx	VPU_VADDR
	ldaa	#7
	staa	VPU_CLINE
	rti
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Reset SPI/EXT devices
spi_reset proc
	psha
	ldaa	#SPI_EXTINI
	oraa	SPI_EXTREG
	staa	SPI_EXTREG

	ldaa	SPI_EXTREG
	anda	#($FF^SPI_EXTRES)
	staa	SPI_EXTREG

	ldaa	SPI_EXTREG
	oraa	#SPI_EXTRES
	staa	SPI_EXTREG
	pula
	rts
	endp

; Check if spi in use
; Return:
; A 0 - not used, 1 - busy
;
spi_getstat proc
	pshx
	eora	#SPI_EXTALL
	psha
	anda	SPI_EXTREG
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
	anda	SPI_EXTREG
	staa	SPI_EXTREG
	bra	okay
disable	oraa	SPI_EXTREG
	staa	SPI_EXTREG
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
sd_show_cmd proc
	rts
	endp

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
loop1	jsr	sd_show_cmd
	cmpa	#$01
	beq	init2
	bsr	sd_delay
	decb
	bne	loop1
	ldaa	#1
	bra	exit

init2	ldx	#sd_init_cmd1
	ldab	#255
loop2	jsr	sd_show_cmd
	tsta
	beq	init3
	bsr	sd_delay
	decb
	bne	loop2
	ldaa	#2
	bra	exit

init3	ldx	#sd_init_cmd16
	jsr	sd_show_cmd
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
	ldab	#1
wait	ldaa	#SPI_EXTSD
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
	pulx
	rts
	endp

sd_disable proc
	psha
	ldaa	#SPI_EXTSD
	ldab	#0
	jsr	spi_select
	jsr	spi_read
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
	jsr	sd_show_cmd
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
	jsr	sd_show_cmd
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
psg_write proc
	psha
	pshb

	psha
	ldab	#1
wait	ldaa	#SPI_EXTPSG
	jsr	spi_select
	tsta
	bne	wait
	pula

	bsr	spi_send
	bsr	bc1off
	tba
	bsr	spi_send
	bsr	bc1on

	ldab	#0
	ldaa	#SPI_EXTREG
	jsr	spi_select
	pulb

	pula
	rts

spi_send pshb
	staa	SPI_DATA
busy	ldab	SPI_STATUS
	bitb	#SPI_READY
	beq	busy
	pulb
	rts

bc1off	psha
	ldaa	SPI_EXTREG
	anda	#($FF^SPI_EXTPSGBC1)
	staa	SPI_EXTREG
	pula
	rts

bc1on	psha
	ldaa	SPI_EXTREG
	oraa	#SPI_EXTPSGBC1
	staa	SPI_EXTREG
	pula
	rts
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
swihndl	proc			; драйвер за обработка на SWI
	sei			; осигурява псевдо-инструкцията INT
	inc	indos		; ниво на вложеност
	tsx
	lds	5,x		; компенсиране на PC за номера на
	des			; интеръпта
	pula			; номер на интеръпта
	ins
	sts	5,x
	txs
	psha
	bsr	exchregs	; размяна на SWI променливите и стека
	pula			; номер на интеръпта
	ldab	rompage 	; текуща ROM страница
	pshb			; спасява се в стека

	tab			; извличане на страницата на интеръпта
	lsrb
	stab	swihndl_x+1
	ldab	#/swipag
	stab	swihndl_x
	ldx	swihndl_x
	ldab	swipag,x
	bcs	swihndl1	;odd-low
	lsrb
	lsrb
	lsrb
	lsrb
swihndl1 andb	#$0f
	beq	swihndl4
	stab	rompage
swihndl4 ldab	#$77		;$ee/2
	asla			; извличане на адреса на интеръпта
	rolb
	staa	swihndl_x+1
	stab	swihndl_x
	ldx	swihndl_x
	ldaa	swivec+1,x
	ldab	swivec,x
	beq	swihndl2
	bsr	swihndl3	; изпълнение на интеръпта
swihndl2 sei			; въстановяване след интеръпта
	pulb
	stab	rompage 	; предишната страница
	tsx
	bsr	exchregs	; размяна на регистрите и стека
	dec	indos		; ниво на вложеност
	rti

exchregs ldaa	1,x
	ldab	swib		; регистър B
	staa	swib
	stab	1,x

	ldaa	2,x
	ldab	swia		; регистър A
	staa	swia
	stab	2,x

	ldaa	3,x
	ldab	swix		; регистър X
	staa	swix
	stab	3,x

	ldaa	4,x
	ldab	swix+1
	staa	swix+1
	stab	4,x

	ldaa	0,x		; регистър P
	ldab	swic
	staa	swic
	stab	0,x
	rts

swihndl3
	psha			; зареждане на регистрите и
	pshb			; изпълнение
	ldaa	swic
	tap
	ldx	swix
	ldab	swib
	ldaa	swia
	cli
	rts
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
dump_regs proc
	ldx	#regstxt
	jsr	uart_puts

	tsx
	ldab	#7

loop	ldaa	0,x		; CC
	jsr	uart_outhex
	ldaa	#' '
	jsr	uart_out
	decb
	bne	loop

	tsx
	inx
	pshx

	pula			; SPH
	jsr	uart_outhex
	pula			; SPL
	jsr	uart_outhex

	rti
	endp

;
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
	bra	dump_regs
	endp

vectextIRQ	db	'IRQ',0
vectextSWI	db	'SWI',0
vectextNMI	db	'NMI',0

regstxt		db	10, 13, 'C- B- A- X--- PC-- SP--', 10, 13, 0

;----
intvectors proc
	global vec_irq, vec_swi, vec_nmi
vec_irq
	ldx	VIRQ
	jmp	0,x

vec_swi
	ldx	VSWI
	jmp	0,x

vec_nmi
	ldx	VNMI
	jmp	0,x
	endp

pylogo		db	10, 13, 'ZERO/pdaXrom BOOTROM'
		db	10, 13, '(c) sashz <sash@pdaXrom>, 1997-2017', 10, 13, 0
txt_bram	db	'Internal RAM enabled.', 10, 13, 0
txt_extram	db	'External RAM enabled.', 10, 13, 0

	ds	$fff8-*, $ff
	dw	vec_irq
	dw	vec_swi
	dw	vec_nmi
	dw	reset
