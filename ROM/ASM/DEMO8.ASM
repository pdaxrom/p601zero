	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	jsr	F_UART_PUTS

	ldx	#$3
	ldd	#$1000

	swi

	bsr	div16

	swi


	ldx	#bye
	jsr	F_UART_PUTS
	jmp	F_RESET

div16	proc
DIV	equ	3
QUO	equ	1
KT	equ	0

	pshx		; dividentd
	pshb		; divisor
	psha		;
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

hello	db	$0a, $0d, 'Hello World!!!', $0a, $0d, 0
bye	db	$0a, $0d, 'Bye!!!', $0a, $0d, 0
