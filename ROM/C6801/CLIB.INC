	include	../DEVMAP.INC
	include	../BOOTROM.INC

	org	$100

	jsr	QZMAIN

	jmp	F_RESET

RT_CCGCHAR proc
	pshb
	psha
	pulx
	clra
	ldab	0,x
	bpl	exit
	deca
exit	rts
	endp

RT_CCGINT proc
	pshb
	psha
	pulx
	ldd	0,x
	rts
	endp

RT_CCSEX proc
	clra
	tstb
	bpl	exit
	deca
exit	rts
	endp

RT_MATH proc
	global RT_CCAND, RT_CCOR, RT_CCXOR, RT_CCNEG
RT_CCAND pshx
	tsx
	anda	0,x
	andb	1,x
	pulx
	rts
RT_CCOR	pshx
	tsx
	oraa	0,x
	orab	1,x
	pulx
	rts
RT_CCXOR pshx
	tsx
	eora	0,x
	eorb	1,x
	pulx
	rts
RT_CCNEG comb
	coma
	addb	#1
	adca	#0
	rts
	endp

RT_COMP	proc
	global RT_CCNE, RT_CCEQ, RT_CCLT, RT_CCGT, RT_CCLE, RT_CCGE
RT_CCNE	bsr	cmpwz
	tstb
	bne	true
	bra	false
RT_CCEQ	bsr	cmpwz
	tstb
	bne	false
	bra	true
RT_CCLT	bsr	cmpwz
	cmpb	#2
	beq	true
	bra	false
RT_CCGT	bsr	cmpwz
	cmpb	#1
	beq	true
	bra	false
RT_CCLE	bsr	cmpwz
	cmpb	#1
	beq	false
	bra	true
RT_CCGE	bsr	cmpwz
	cmpb	#2
	beq	false
	bra	true
false	ldd	#0
	rts
true	ldd	#1
	rts

cmpwz	pshx
	tsx
	cmpa 	0,x
	bgt 	mgt
	blt	mlt
	cmpb	1,x
	beq	meq
	;bmi	mlt
	;blt	mlt
	bls	mlt
	bra	mgt
meq	clrb
	bra	exit
mlt	ldab 	#1
	bra	exit
mgt	ldab    #2
exit	pulx
	rts
	endp

RT_CCDIV proc
DIV	equ	3
QUO	equ	1
KT	equ	0

	pshb		; divisor
	psha		;
	pshx		; dividend
	ldab	#1
	pshb		; counter
	tsx

	ldd	DIV,x
	beq	error
	bmi	DIV002
DIV001	inc	KT,x
	asld
	bpl	DIV001
	std	DIV,x
DIV002	ldd	QUO,x
	clr	QUO,x
	clr	QUO+1,x
DIV003	subd	DIV,x
	bcc	DIV004
	addd	DIV,x
	clc
	bra	DIV005
DIV004	sec
DIV005	rol	QUO+1,x
	rol	QUO,x
	lsr	DIV,x
	ror	DIV+1,x
	dec	KT,x
	bne	DIV003

	pshb
	psha
	ldd	QUO,x
	pulx

	clc
	bra	okay
error	sec
okay	ins
	ins
	ins
	ins
	ins
	rts
	endp

QZPUTC	proc
	tsx
	ldaa	2,x
	jmp	F_UART_OUT
	endp

QZPUTS	proc
	tsx
	ldx	2,x
	jmp	F_UART_PUTS
	endp

QZPUTHEX proc
	tsx
	ldaa	2,x
	jmp	F_UART_OUTHEX
	endp
