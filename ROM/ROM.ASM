;
; Check UART IO
;

	org	$ff00

reset
	sei

	lds	#$ef
; setup prescaler: Fclk / (Baud * 8)
	ldx	#39
	stx	$e60a

	ldaa	$e60b
	staa	$e602

	ldaa	$e60a
	staa	$e600


	ldab	#0
loop
	ldaa	$e609

;	staa	$e600

	anda	#$1
	cmpa	#0
	beq	loop
	ldaa	$e608
	staa	$e602
	incb
	stab	$e600
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
