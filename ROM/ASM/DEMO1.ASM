	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	int	F_UART_PUTS

	ldd	#$02
	asld

	int	F_BPT

	ldx	#bye
	int	F_UART_PUTS

	int	F_WARMRES

hello	db	10, 13, 'Hello World!!!', 10, 13, 0
bye	db	10, 13, 'Bye!!!', 10, 13, 0
title	db	$0c, 'Hello world!', 10, 13, 'HAHA', $1e, $25, $25, '+'
	db	$1e, $26, $20, $18, 'people'
	db	$1e, $23, $21, '*', $08, $7f, 10, 13
	db	'1', $09, '2', $09, '3', $09, '4', $1b, $01, 0
