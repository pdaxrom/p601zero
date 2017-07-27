	include ../DEVMAP.INC

	include ../BOOTROM.INC

SCRADDR		equ	$F560
SCRSZX		equ	$F562
SCRSZY		equ	$F563

	org $100

	aby
	ldaa	0,x
	ldaa	0,y

	addd	0,x
	addd	0,y

	idiv
	fdiv

	cpd	#$babe
	cpd	$80
	cpd	$8080
	cpd	0,x
	cpd	0,y

	cpx	#$babe
	cpx	$80
	cpx	$8080
	cpx	0,x
	cpx	0,y

	cpy	#$babe
	cpy	$80
	cpy	$8080
	cpy	0,x
	cpy	0,y

	ldx	#$babe
	ldx	$80
	ldx	$8080
	ldx	0,x
	ldx	0,y

	ldy	#$babe
	ldy	$80
	ldy	$8080
	ldy	0,x
	ldy	0,y

	stop

loop	int	F_UART_IN
	int 	$22
	cmpa	#$1b
	beq	exit
	bra	loop
exit	int	F_WARMRES

hello	db	10, 13, 'Hello World!!!', 10, 13, 0
bye	db	10, 13, 'Bye!!!', 10, 13, 0
title	db	$0c, 'Hello world!', 10, 13, 'HAHA', $1e, $25, $25, '+'
	db	$1e, $26, $20, $18, 'people'
	db	$1e, $23, $21, '*', $08, $7f, 10, 13
	db	'1', $09, '2', $09, '3', $09, '4', $1b, $01, 0
