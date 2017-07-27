;
; BOOTROM for Z/pdaXrom
; (c) sashz <sashz@pdaXrom.org>, 2017
;

		include DEVMAP.INC

;
; BootROM variables and functions
;

		include BOOTROM.INC

		include BOOTMEM.INC

		include FAT16.INC

		org	$C000
		dw	$A55A
		db	'Z/KERNEL'
		jmp	p601_init
		jmp	p601_monitor
		db	0		; No Pyldin 601 swi calls here
p601_init	rts
p601_monitor	rts
init		ldx	#title
		int	F_PUTSTR

; install syscalls
		ldx	#romvecbeg
romvecinst	ldaa	0,x
		tsta
		beq	romvecexit
		pshx
		ldx	1,x
		ldab	RAMPAGE_SEL
    int F_BPT
		jsr	setvector
		pulx
		inx
		inx
		inx
		bra	romvecinst
romvecexit

		ldaa	#$E0
		int	$E0
		int	F_BPT
		ldaa	#$E1
		int	$E0
		int	F_BPT

		int	F_WARMRES
		rts

getvector	proc
		sei
		tab
		ldx	#BROM_SWIPAG
		lsrb
		abx
		ldab	0,x
		bcc	swih1
		lsrb
		lsrb
		lsrb
		lsrb
swih1		andb	#$0F
		pshb
		tab
		ldx	#BROM_SWIVEC
		abx
		abx
		ldx	0,x
		pulb
		rts
		endp

setvector	proc
		sei
		pshx
		pshb
		psha

		pshx
		psha
		pshb
		tab
		ldx	#BROM_SWIPAG
		lsrb
		abx
		ldaa	0,x
		pulb
		pshx
		bcc	next1
		anda	#$0F
		lslb
		lslb
		lslb
		lslb
		bra	next2
next1		anda	#$F0
		andb	#$0F
next2		pshb
		tsx
		oraa	0,x
		pulb
		pulx
		staa	0,x
		pulb
		ldx	#BROM_SWIVEC
		abx
		abx
		pula
		pulb
		std	0,x

		pula
		pulb
		pulx
		rts
		endp

title		db	'ZBIOS loaded.', 10, 13, 0

romvecbeg
		db	$E0
		dw	getvector
		db	$E1
		dw	setvector
		db	0
romvecend
		checksum
		ds	$DFFE-*,$FF
		dw	init
