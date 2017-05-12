;
; UART Module
;

	include DEVMAP.INC

	org	$ff00

reset
	sei

	lds	#$ef

; setup prescaler: 12MHz / (Baud * 8)
	ldx	#156
	stx	UART_PRESCALER

	ldaa	UART_PRESCALER
	staa	LED_HEX

	ldaa	UART_PRESCALER+1
	staa	LED_8BIT

; disable UART interrupts (clear UART_TIE and UART_RIE)
	clra
	staa	UART_CONFIG

	ldx	#pylogo
	bsr	uart_print

;	ldaa	#'$'
;	bsr	uart_out
;	ldaa	#'>'
;	bsr	uart_out

	ldab	#0
loop
	bsr	uart_in
	staa	LED_HEX
	bsr	uart_out

	incb
	stab	LED_8BIT
	bra	loop

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

uart_print proc
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

pylogo	db 'BE601Z (c) sashz@pdaXrom.org, 2017', $0a, $0d, 0

;----
;----
vec_irq	proc
; Check if interrupt from timer
	ldaa	TIMER_STATUS
	bita	#TIMER_IRQ
	beq	ret
; Increase time
	ldaa	$10
	staa	LED_HEX
	ldx	$11
	inx
	stx	$11
	cpx	#50
	bne	ret
	clr	$11
	clr	$12
	inc	$10
ret	rti
	endp

vec_swi	proc
	rti
	endp

vec_nmi	proc
	rti
	endp

	ds	$fff8-*, $ff
	dw	vec_irq
	dw	vec_swi
	dw	vec_nmi
	dw	reset
