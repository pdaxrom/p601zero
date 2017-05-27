;
; Check RTC IRQ
;

	include DEVMAP.INC

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
	ldaa	#(TIMER_IEN | TIMER_RUN)
	staa	TIMER_CONFIG

	cli
loop
	ldaa	INPUT_SWKEYS
	staa	LED_8BIT
	bra	loop
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
