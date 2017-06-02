;
; UART BOOTROM for BLACK EYES 601 Zero
; (c) sashz <sashz@pdaXrom.org>, 2017
;

	include DEVMAP.INC

	include BOOTROM.INC

	org	BOOTROM_BASE

	jmp	reset
	jmp	uart_in
	jmp	uart_out
	jmp	uart_puts
	jmp	uart_outhex_1
;	jmp	sd_init

reset
	sei

	lds	#$ef

; setup stubs
	ldx	#vstub_irq
	stx	VIRQ
	ldx	#vstub_swi
	stx	VSWI
	ldx	#vstub_nmi
	stx	VNMI

; setup prescaler: 24MHz / (Baud * 8)
	ldx	#26
	stx	UART_PRESCALER

; disable UART interrupts (clear UART_TIE and UART_RIE)
	clra
	staa	UART_CONFIG

	ldx	#pylogo
	bsr	uart_puts

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
	jmp	0,x

get_block_addr proc
	bsr	get_word
	pshx
	bsr	get_word
	stx	END_ADDR
	pulx
	rts
	endp

uart_outhex_1
	bra	uart_outhex

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

pylogo	db $0a, $0d, 'ZERO/pdaXrom', $0a, $0d, 0

dump_regs proc
	sts	$10

	lds	#$80

	ldx	#regstxt
	bsr	uart_puts

	ldx	$10
	inx

	ldaa	0,x		; CC
	bsr	uart_outhex
	ldaa	#' '
	bsr	uart_out

	ldaa	1,x		; A
	bsr	uart_outhex
	ldaa	#' '
	bsr	uart_out

	ldaa	2,x		; B
	bsr	uart_outhex
	ldaa	#' '
	bsr	uart_out

	ldaa	3,x		; XH
	bsr	uart_outhex
	ldaa	4,x		; XL
	bsr	uart_outhex
	ldaa	#' '
	jsr	uart_out

	ldaa	5,x		; PCH
	bsr	uart_outhex
	ldaa	6,x		; PCL
	bsr	uart_outhex
	ldaa	#' '
	jsr	uart_out

	dex
	pshx

	pula			; SPH
	jsr	uart_outhex
	pula			; SPL
	jsr	uart_outhex

	lds	$10

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
	jmp	dump_regs
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

	ds	$fff8-*, $ff
	dw	vec_irq
	dw	vec_swi
	dw	vec_nmi
	dw	reset
