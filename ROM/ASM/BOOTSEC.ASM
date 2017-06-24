	include ../DEVMAP.INC

	include ../BOOTROM.INC

	include FAT16.INC

	org $100

	ldx	#hello
	int	F_UART_PUTS

	int	F_SD_INIT
	tsta
	beq	next
	jmp	inierr

next	ldd	#0
	std	read_sec
	std	read_sec+2

	ldx	#boot_buf
	stx	read_sec+4

	ldx	#read_sec
	int	F_SD_READ
	tsta
	beq	next1
	jmp	readerr

next1	ldx	#boot_buf
	ldaa	_reserved_sectors+1,x
	ldab	_reserved_sectors,x
;	int	F_BPT
	std	read_sec+2
	ldaa	_sectors_per_fat+1,x
	ldab	_sectors_per_fat,x
;	int	F_BPT
	pshb
	psha
	clra
	ldab	_fats,x
	pulx
;	int	F_BPT
	int	F_UMULT
;	int	F_BPT

;	ldx	read_sec+2
;	int	F_BPT

	addd	read_sec+2
	std	read_sec+2

;	int	F_BPT

	ldx	#boot_buf
	ldaa	_root_entries+1,x
	ldab	_root_entries,x
	std	root_entries
	ldx	#32
	int	F_UMULT

	pshb
	psha
	ldx	#boot_buf
	ldaa	_bytes_per_sector+1,x
	ldab	_bytes_per_sector,x
	pulx
	int	F_UDIV
	std	size

	int	F_BPT

	ldd	read_sec+2
	ldx	read_sec

;	int	F_BPT

	ldx	#dir_buf
	stx	read_sec+4
	ldx	#read_sec
	int	F_SD_READ
	tsta
	bne	readerr

	ldx	#dir_buf
	stx	ptr_entry

readdir	ldd	ptr_entry
	ldx	#bootfile
	bsr	strcmp
	beq	loadfile
	ldd	ptr_entry
	addd	#32
	std	ptr_entry
	xgdx
	cpx	#dir_buf+512
	bne	readdir
	bra	readerr

loadfile
;	int	F_BPT

	ldx	ptr_entry
	ldaa	_cluster+1,x
	ldab	_cluster,x
	subd	#2
	pshb
	psha

	ldx	#boot_buf
	clra
	ldab	_sectors_per_cluster,x
	pulx

	int	F_UMULT
	addd	size

	addd	read_sec+2

	int	F_BPT

	std	read_sec+2

	ldx	read_sec
	ldd	read_sec+2

	int	F_BPT

	ldx	#file_buf
	stx	read_sec+4

	ldaa	#16
	staa	counter

load1	ldx	#read_sec
	int	F_SD_READ
	tsta
	bne	readerr
	ldd	read_sec+2
	addd	#1
	std	read_sec+2
	ldd	read_sec+4
	addd	#512
	std	read_sec+4
	dec	counter
	bne	load1

;	int	F_BPT

exit	ldx	#bye
exit1	int	F_UART_PUTS

	int	F_WARMRES

inierr	ldx	#err1txt
	bra	exit1
readerr	ldx	#err2txt
	bra	exit1

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

root_entries dw	0
ptr_entry dw 0

counter	db	0

read_sec db	$00,$00,$00,$00
	dw	0

lba	dw	0
size	dw	0

boot_buf equ	$400
dir_buf	equ	$600
file_buf equ	$800

hello	db	'Booting IO.SYS', $0a, $0d, 0
err1txt	db	'Can not initialize boot storage!', 10, 13, 0
err2txt	db	'Read error!', 10, 13, 0
bye	db	'Starting IO.SYS', $0a, $0d, 0
