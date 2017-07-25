	include DEVMAP.INC

	include BOOTROM.INC

	include FAT16.INC

boot_buf	equ	$400
dir_buf		equ	$600
kernel_addr	equ	$c000
kernel_page	equ	$f
kernel_initvec	equ	$dffe

		section $80
root_entries	ds	2
ptr_entry	ds	2

counter		ds	1

read_sec	ds	6

lba		ds	2
size		ds	2
		ends

	org $13E

	ldx	#hello
	int	F_PUTSTR

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
	std	read_sec+2
	ldaa	_sectors_per_fat+1,x
	ldab	_sectors_per_fat,x
	pshb
	psha
	clra
	ldab	_fats,x
	pulx
	int	F_UMULT
	addd	read_sec+2
	std	read_sec+2

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

	ldx	#dir_buf
	stx	read_sec+4
	ldx	#read_sec
	int	F_SD_READ
	tsta
	beq	next2
	jmp	readerr

next2	ldx	#dir_buf
	stx	ptr_entry

readdir	ldd	ptr_entry
	ldx	#bootfile
	jsr	strcmp
	beq	loadfile
	ldd	ptr_entry
	addd	#32
	std	ptr_entry
	xgdx
	cpx	#dir_buf+512
	bne	readdir
	bra	readerr

loadfile ldx	ptr_entry
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
	std	read_sec+2

	ldaa	RAMPAGE_CTL
	anda	#($FF ^ RAMPAGE_LOCK)
	staa	RAMPAGE_CTL
	ldaa	#kernel_page
	staa	RAMPAGE_SEL

	ldx	#kernel_addr
	stx	read_sec+4
	ldaa	#16
	staa	counter
load1	ldx	#read_sec
	int	F_SD_READ
	tsta
	bne	readerr
	ldaa	#'.'
	int	F_PUTCHAR
	ldd	read_sec+2
	addd	#1
	std	read_sec+2
	ldd	read_sec+4
	addd	#512
	std	read_sec+4
	dec	counter
	bne	load1

	ldx	#done
	int	F_PUTSTR

	ldx	kernel_initvec
	jmp	0,x

exit	ldx	#bye
exit1	int	F_PUTSTR

	rts

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

;bootfile	db	'IO      SYS',0
bootfile	db	'KERNEL  SYS',0

hello		db	'Booting KERNEL.SYS ', 0
err1txt		db	' failed.', 10, 13, 'Storage init error!', 10, 13, 0
err2txt		db	' failed.', 10, 13, 'Loading error!', 10, 13, 0
done		db	' done.', $0a, $0d, 0
bye		db	'Something went wrong, return to BOOTROM :(', 0

		ds	$2fe-*,$ff
		db	$55, $aa
