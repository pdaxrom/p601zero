;
; BOOTROM for Z/pdaXrom
; (c) sashz <sashz@pdaXrom.org>, 2017
;

	include DEVMAP.INC

	include BOOTROM.INC

	org	$ff00

	bra	reset
	bra	uart_in
	bra	uart_out
	bra	uart_puts
	bra	uart_outhex_1

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

; setup prescaler: 12MHz / (Baud * 8)
	ldx	#13
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
ret	bsr	uart_puts
	rti
	endp

vectextIRQ	db	'IRQ',0
vectextSWI	db	'SWI',0
vectextNMI	db	'NMI',0

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
