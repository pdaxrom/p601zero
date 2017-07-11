	include ../DEVMAP.INC

	include ../BOOTROM.INC

SCRADDR		equ	$F560
SCRSZX		equ	$F562
SCRSZY		equ	$F563

	org $100

	ldd	#100
	subd	#60

	int	F_BPT


	int	F_WARMRES

hello	db	10, 13, 'Hello World!!!', 10, 13, 0
bye	db	10, 13, 'Bye!!!', 10, 13, 0
title	db	$0c, 'Hello world!', 10, 13, 'HAHA', $1e, $25, $25, '+'
	db	$1e, $26, $20, $18, 'people'
	db	$1e, $23, $21, '*', $08, $7f, 10, 13
	db	'1', $09, '2', $09, '3', $09, '4', $1b, $01, 0
