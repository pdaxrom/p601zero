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

	org	$ff00

reset
	sei

	lds	#$ef

	clr	$10
	clr	$11
	clr	$12

; Setup timer
	ldaa	#0
	staa	TIMER_CONFIG
; Set 50 Hz interrupts
	staa	TIMER_PRESCALER
	ldx	#59999
	stx	TIMER_PRESCALER+1
; Enable interrupts and start timer
	ldaa	#$41
	staa	TIMER_CONFIG

	cli
loop
	ldaa	INPUT_SWKEYS
	staa	LED_8BIT
	bra	loop
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
