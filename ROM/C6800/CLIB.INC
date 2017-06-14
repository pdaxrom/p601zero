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

QZPUTC	proc
	tsx
	inx
	inx
	ldaa	1,x
	jmp	F_UART_OUTHEX
	endp

QZPUTS	proc
	tsx
	inx
	inx
	ldx	0,x
	jmp	F_UART_PUTS
	endp
