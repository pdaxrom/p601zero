		include ../DEVMAP.INC

		include ../BOOTROM.INC

		include ../FAT16.INC

boot_buf	equ	$400
dir_buf		equ	$600
fil_buf		equ	$800
kernel_addr	equ	$c000
kernel_page	equ	$f
kernel_initvec	equ	$dffe

		section 0
fats		ds	2
fatsize		ds	2
root_entries	ds	2
fat_start	ds	2
root_start	ds	2
data_start	ds	2
sectorsize	ds	2
clustersize	ds	2

read_sec	ds	6

file_left	ds	4
cluster_left	ds	4
ptr_entry	ds	2
ff_size		ds	0
		ends

		org $100

		lds	#$afff
		ldx	#title
		int	F_PUTSTR

		ldx	#table_42
		jsr	opendir

loop		cmpa	#$0b
		beq	read_file
		tsta
		bne	exit_err

		ldx	#dir_entry
		jsr	printdname
		ldx	#crlf
		int	F_PUTSTR

		ldx	#table_42
		jsr	readdir

		bra	loop


read_file	ldx	#table_42
		jsr	opendir
		jsr	readdir
		jsr	readdir

		ldx	#table_42
		jsr	openfile

		bra	exit_dir

exit_err	ldx	#t_error
		int	F_PUTSTR

exit_dir	jmp	$c013

title		db	'FAT16 Driver', 10, 13, 0

t_error		db	'Error!', 10, 13, 0

t_initerr	db	'SD init error', 10, 13, 0
t_bterr		db	'Boot sector read error', 10, 13, 0
t_rderr		db	'Directory sector read error', 10, 13, 0

t_btok		db	'Boot sector ok', 10, 13, 0
t_exit		db	'Exit...', 10, 13, 0

crlf		db	10, 13, 0

printdname	proc
		pshb
		psha
		pshx

		ldab	#8
		bsr	printn
		ldaa	#'.'
		int	F_PUTCHAR
		ldab	#3
		bsr	printn
		pulx
		pula
		pulb
		rts
printn		ldaa	0,x
		cmpa	#' '
		beq	printn1
		int	F_PUTCHAR
printn1		inx
		decb
		bne	printn
		rts
		endp

;
;
;
opendir		proc
		global	readdir
		pshb
		pshy
		pshx
		int	F_SD_INIT
		tsta
		beq	next
		ldx	#t_initerr
		bra	error

next		ldy	0,x
		jsr	fat_open
		tsta
		bne	error

		ldd	#0
		std	ptr_entry,y

		ldx	#t_btok
		int	F_PUTSTR

		ldx	#dir_buf
		stx	read_sec+4,y

rdir2		jsr	read_sector
		tsta
		bne	err_dirr
		pulx
		pshx
		ldx	2,x
		bsr	cp_dir_rec
		tsta
		beq	next2
nomore		ldaa	#$0B
		bra	exit
next2		ldd	file_left+2,y
		subd	#32
		std	file_left+2,y
		ldd	ptr_entry,y
		addd	#32
		cmpd	sectorsize,y
		bne	next1
		ldd	read_sec+2,y
		addd	#1
		std	read_sec+2,y
		ldd	#0
next1		std	ptr_entry,y
		bra	exit
err_dirr	ldx	#t_rderr
		bra	err_out
error		ldx	#t_bterr
err_out		int	F_PUTSTR
exit		ldx	#t_exit
		int	F_PUTSTR
		pulx
		puly
		pulb
		rts
cp_dir_rec	pshy
		ldd	ptr_entry,y
		anda	#1
		addd	read_sec+4,y
		xgdx
		xgdy
		ldaa	#32
		tst	0,x
		beq	cp_dir_rec2
cp_dir_rec1	ldab	0,x
		stab	0,y
		iny
		inx
		deca
		bne	cp_dir_rec1
cp_dir_rec2	puly
		rts
readdir		pshb
		pshy
		pshx
		ldy	0,x
		ldd	file_left+2,y
		bne	rdir2
		bra	nomore
		endp

;
;
;
openfile	proc
		pshb
		pshy
		pshx
		ldy	0,x
		ldx	2,x
		ldaa	_cluster+1,x
		ldab	_cluster,x
		subd	#2
		ldx	clustersize,y
		int	F_UMULT
		addd	data_start,y
		std	read_sec+2,y
		xgdx
		adcb	#0
		adca	#0
		std	read_sec,y

		ldx	#fil_buf
		stx	read_sec+4,y

		jsr	read_sector

		tsta
		bne	exit

		pulx
		pshx
		ldy	0,x
		ldx	2,x
		ldaa	_cluster+1,x
		ldab	_cluster,x
		int	F_BPT
		bsr	getnextcluster
		int	F_BPT

exit		pulx
		puly
		pulb
		rts
		endp

;
; Convert cluster number to sector
; In: D - cluster
; Out: XD - sector
;
cluster2sec	proc
		subd	#2
		ldx	clustersize,y
		int	F_UMULT
		addd	data_start,y
		xgdx
		adcb	#0
		adca	#0
		xgdx
		rts
		endp

;
; Get next cluster
; In: D - current cluster
; Out: D - next cluster
;
getnextcluster	proc
		pshb
		tab
		clra
		lsld
		addd	fat_start,y
		std	read_sec+2,y
		subd	read_sec+2,y
		std	read_sec,y
		ldx	#boot_buf
		stx	read_sec+4,y
		jsr	read_sector
		pulb
		clra
		lsld
		addd	read_sec+4,y
		xgdx
		ldab	0,x
		ldaa	1,x
		rts
		endp

;
;
;
fat_open	proc
; read boot sector to init structure
		ldd	#0
		std	read_sec,y
		std	read_sec+2,y

		ldx	#boot_buf
		stx	read_sec+4,y

		jsr	read_sector

		tsta
		beq	next1
		rts

; save sector size
next1		ldx	#boot_buf
		ldaa	_bytes_per_sector+1,x
		ldab	_bytes_per_sector,x
		std	sectorsize,y

; save fats
		clra
		ldab	_fats,x
		std	fats,y

; save sectors per fat
		ldaa	_sectors_per_fat+1,x
		ldab	_sectors_per_fat,x
		std	fatsize,y

; save sectors per cluster
		clra
		ldab	_sectors_per_cluster,x
		std	clustersize,y

; save root entries
		ldaa	_root_entries+1,x
		ldab	_root_entries,x
		std	root_entries,y

; save reserved sectors
		ldaa	_reserved_sectors+1,x
		ldab	_reserved_sectors,x
		std	fat_start,y		; fat_start = _reserved_sectors

		ldx	fatsize,y
		ldd	fats,y
		int	F_UMULT

		addd	fat_start,y
		std	root_start,y
		std	read_sec+2,y		; root_start += fatsize * fats

		ldd	root_entries,y
		ldx	#32
		int	F_UMULT
		std	file_left+2,y		; for count dir entries during open function
		xgdx
		ldd	sectorsize,y
		int	F_UDIV
		addd	root_start,y
		std	data_start,y		; data_start = fat_start + root_entries * 32 / sectorsize

		ldd	#$ffff
		std	cluster_left,y		;
		std	cluster_left+2,y	;
		ldd	#0
		std	file_left,y		;
		clra
		rts
		endp

;
;
;
read_sector	proc
		pshy
		xgdy
		addd	#read_sec
		xgdx
		int	F_SD_READ
		puly
		rts
		endp

ff_block	ds	ff_size

dir_entry	ds	32

file_name	db	'KERNEL.SYS',0

table_42	dw	ff_block
		dw	dir_entry
		dw	file_name

table_43	dw	ff_block
		dw	dir_entry
