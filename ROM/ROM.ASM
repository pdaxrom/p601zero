;
; UART Module
;

	include DEVMAP.INC

	include BOOTROM.INC

	org	$ff00

	bra	reset
	bra	uart_in
	bra	uart_out
	bra	uart_puts

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
	staa	LED_HEX
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
	stx	START_ADDR
	bsr	get_word
	stx	END_ADDR
	ldx	START_ADDR
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

get_word proc
	psha
	bsr	uart_in
	tab
	bsr	uart_in
	psha
	pshb
	pulx
	pula
	rts
	endp

pylogo	db 'ZERO/pdaXrom', $0a, $0d, 0

;----
vstub_irq proc
	ldx	#vectextIRQ
	bsr	uart_puts
	rti
	endp

vstub_swi proc
	ldx	#vectextSWI
	bsr	uart_puts
	rti
	endp

vstub_nmi proc
	ldx	#vectextNMI
	bsr	uart_puts
	rti
	endp

vectextIRQ	db	$a,$d,'IRQ',$a,$d,0
vectextSWI	db	$a,$d,'SWI',$a,$d,0
vectextNMI	db	$a,$d,'NMI',$a,$d,0

;----
vec_irq	proc
	ldx	VIRQ
	jmp	0,x
	endp

vec_swi	proc
	ldx	VSWI
	jmp	0,x
	endp

vec_nmi	proc
	ldx	VNMI
	jmp	0,x
	endp

	ds	$fff8-*, $ff
	dw	vec_irq
	dw	vec_swi
	dw	vec_nmi
	dw	reset
