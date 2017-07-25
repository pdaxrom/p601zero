	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	int	F_PUTSTR

	ldaa	#SPI_PSG
	ldab	#1
	int	F_SPI_SELECT
	tsta
	beq	loop
	ldx	#busy
	int	F_PUTSTR
	bra	exit1

loop	ldx	#buf
read	int	F_UART_IN
	staa	0,x
	inx
	cpx	#buf+16
	bne	read

	ldx	#buf
	ldaa	#14

	int	F_PSG_WRITE

	ldaa	IO_SWKEYS
	bita	#1
	beq	loop

exit
	ldaa	#SPI_PSG
	ldab	#0
	int	F_SPI_SELECT

exit1	ldx	#bye
	int	F_PUTSTR
	int	F_WARMRES

hello	db	$0c, $0a, $0d, 'AY-3-8912 SERIAL CHIPTUNE!', $0a, $0d, 0
busy	db	'SPI busy, try again', 0
bye	db	$0a, $0d, 'Bye!', $0a, $0d, 0

buf	ds	16
