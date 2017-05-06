;
; Check UART IO
;

UART_DATA	equ	$e608
UART_STATUS	equ	$e609
UART_PRESCALER	equ	$e60a

UART_RX_READY	equ	$1
UART_TX_READY	equ	$8


	org	$ff00

reset
	sei

	lds	#$ef
; setup prescaler: Fclk / (Baud * 8)
	ldx	#39
	stx	UART_PRESCALER

	ldaa	$e60b
	staa	$e602

	ldaa	$e60a
	staa	$e600


	ldab	#0
loop
;	ldaa	UART_STATUS
;	bita	#UART_RX_READY
;	beq	loop
;	ldaa	UART_DATA

	bsr	uart_in

	staa	$e602
	incb
	stab	$e600
	bra	loop

;;
uart_in proc
	ldaa	UART_STATUS
	bita	#UART_RX_READY
	beq	uart_in
	ldaa	UART_DATA
	rts
	endp

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
	rti
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
