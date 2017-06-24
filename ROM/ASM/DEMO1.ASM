	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	int	F_UART_PUTS

	ldd	#file
	ldx	#bootfile
	bsr	strcmp

	int	F_BPT

	ldx	#bye
	int	F_UART_PUTS

	int	F_WARMRES

; Compare string
; AB, X (zero ended)
; A = 0 Okay
strcmp	proc
	pshb
	psha
	pshx
	tsx
loop	ldx	0,x
	ldaa	0,x
	beq	okay
	tsx
	pshb
	psha
	ldd	0,x
	addd	#1
	std	0,x
	pula
	pulb
	ldx	2,x
	cmpa	0,x
	bne	fail
	tsx
	pshb
	psha
	ldd	2,x
	addd	#1
	std	2,x
	pula
	pulb
	bra	loop
fail	lda	#1
	bra	exit
okay	lda	#0
exit	pulx
	ins
	ins
	rts
	endp

bootfile db	'IO      SYS',0

file	db	'IO      SYS'

hello	db	10, 13, 'Hello World!!!', 10, 13, 0
bye	db	10, 13, 'Bye!!!', 10, 13, 0
title	db	$0c, 'Hello world!', 10, 13, 'HAHA', $1e, $25, $25, '+'
	db	$1e, $26, $20, $18, 'people'
	db	$1e, $23, $21, '*', $08, $7f, 10, 13
	db	'1', $09, '2', $09, '3', $09, '4', $1b, $01, 0
