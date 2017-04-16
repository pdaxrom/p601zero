	org	$ff00

reset
	sei

	lds	#$ef

loop
	ldaa	$e604
	staa	$e600
	staa	$e602
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
