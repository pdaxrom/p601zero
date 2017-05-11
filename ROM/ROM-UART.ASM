;
; Check RTC IRQ
;

LED_8BIT	equ	$E6A0
LED_2RGB	equ	$E6A1
LED_HEX		equ	$E6A2
INPUT_SWKEYS	equ	$E6A3

TIMER_CONFIG	equ	$E6A4
TIMER_STATUS	equ	$E6A4
TIMER_PRESCALER	equ	$E6A5

UART_DATA	equ	$E6A8
UART_STATUS	equ	$E6A9
UART_PRESCALER	equ	$E6AA

UART_RX_READY	equ	$1
UART_TX_READY	equ	$10

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

; flush receiver after setup to prevent corrupted data
;	ldaa	UART_DATA
;	ldaa	#'@'
;	staa	UART_DATA

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
	bita	#UART_RX_READY
	beq	uart_in
	ldaa	UART_DATA
	rts
	endp

uart_out proc
	pshb
loop	ldab	UART_STATUS
	bitb	#UART_TX_READY
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

pylogo	db 'P601ZERO (c) sashz@pdaXrom.org, 2017', $0a, $0d, 0

;----
;----
vec_trap proc
	rti
	endp

vec_sci proc
	rti
	endp

vec_tof	proc
	rti
	endp

vec_ocf	proc
	rti
	endp

vec_icf	proc
	rti
	endp

vec_irq	proc
; Check if interrupt from timer
	ldaa	TIMER_STATUS
	anda	#$80
	cmpa	#$80
	bne	ret
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

	ds	$ffee-*, $ff
	dw	vec_trap
	dw	vec_sci
	dw	vec_tof
	dw	vec_ocf
	dw	vec_icf
	dw	vec_irq
	dw	vec_swi
	dw	vec_nmi
	dw	reset
