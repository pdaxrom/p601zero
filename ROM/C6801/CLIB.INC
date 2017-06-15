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

RT_CCGCHAR1 proc
	pshb
	psha
	pulx
	clra
	ldab	1,x
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

QZPUTC	proc
	tsx
	ldaa	3,x
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
