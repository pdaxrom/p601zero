	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	int	F_UART_PUTS

	int	$13
	int	F_BPT


	ldx	#title
	int	$23

	int	F_UART_IN

	ldx	#bye
	int	F_UART_PUTS

	int	F_WARMRES

hello	db	10, 13, 'Hello World!!!', 10, 13, 0
bye	db	10, 13, 'Bye!!!', 10, 13, 0
title	db	'Hello world!', 10, 13, 'HAHA', $1e, $25, $25, '+', 0
