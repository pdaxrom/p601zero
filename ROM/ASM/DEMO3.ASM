	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	int	F_UART_PUTS

	ldaa	#$41
	ldab	#$42
	ldx	#$4344

	int	F_SHOWREGS

	pshx
	int	F_UART_OUTHEX
	tba
	int	F_UART_OUTHEX
	pula
	int	F_UART_OUTHEX
	pula
	int	F_UART_OUTHEX

	ldx	#bye
	int	F_UART_PUTS
	int	F_WARMRES

hello	db	$0a, $0d, 'Hello World!!!', $0a, $0d, 0
bye	db	$0a, $0d, 'Bye!!!', $0a, $0d, 0
