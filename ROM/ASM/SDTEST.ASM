	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	int	F_PUTSTR

	int	F_SD_INIT

	int	F_BPT

	tsta
	bne	exit

	ldx	#read_sec
	int	F_SD_READ

	int F_BPT

	ldx	#read_sec2
	int	F_SD_READ

	int F_BPT

	ldx	#write_sec
	int	F_SD_WRITE

	int F_BPT

	ldx	#write_sec2
	int	F_SD_WRITE

	int F_BPT

	int	F_SD_FLUSH

	int F_BPT

exit	ldx	#bye
	int	F_PUTSTR

	int	F_WARMRES

read_sec db	$00,$00,$00,$00
	dw	read_buf
read_sec2 db	$00,$00,$00,$01
	dw	read_buf2

write_sec db	$00,$00,$00,$01
	dw	read_buf
write_sec2 db	$00,$00,$00,$00
	dw	read_buf2

read_buf  equ $400
read_buf2 equ $600

hello	db	$0a, $0d, 'SD Card test!', $0a, $0d, 0
bye	db	$0a, $0d, 'Bye!', $0a, $0d, 0
