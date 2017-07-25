;
; External RAM checker
; Run:
; ../bootloader /dev/ttyUSB0 load RAMCHK.CMD e800
; ../bootloader /dev/ttyUSB0 go e800
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $e800

	lds	#$efef

; disable ram pages
	clr	RAMPAGE_SEL
	ldaa	RAMPAGE_CTL
	oraa	#BRAM_DISABLE
	staa	RAMPAGE_CTL

	ldx	#hello
	int	F_PUTSTR

	ldx	#$0000
	stx	RAM_START
	ldx	#$E000
	stx	RAM_END

;
;
;
	ldaa	#$00
	jsr	fillbyte

	ldaa	#$ff
	jsr	fillbyte

	ldaa	#$aa
	jsr	fillbyte

	ldaa	#$55
	jsr	fillbyte

	ldaa	#$a5
	jsr	fillbyte

	ldaa	#$5a
	jsr	fillbyte

;
;
;
	ldaa	#8
	staa	RAM_STEP

	ldaa	#$00
	jsr	fillbyte_step

	ldaa	#$ff
	jsr	fillbyte_step

	ldaa	#$aa
	jsr	fillbyte_step

	ldaa	#$55
	jsr	fillbyte_step

	ldaa	#$a5
	jsr	fillbyte_step

	ldaa	#$5a
	jsr	fillbyte_step

;
;
;
	jsr	fillram

	int	F_UART_IN

	int	F_WARMRES

fillram proc
	ldaa	#0
loop	ldx	#fillram1
	int	F_PUTSTR
	int	F_PUTHEX
	ldx	RAM_START
loopw	staa	0,x
	inx
	cpx	RAM_END
	bne	loopw
	ldx	RAM_START
loopr	ldab	0,x
	cba
	bne	error
	inx
	cpx	RAM_END
	bne	loopr
	ldx	#okay
	int	F_PUTSTR
	inca
	cmpa	#0
	bne	loop
	rts
error	pshx
	ldx	#failed
	int	F_PUTSTR
	tba
	int	F_PUTHEX
	ldx	#failed1
	int	F_PUTSTR
	pulx
	ldab	#16
err1	ldaa	0,x
	int	F_PUTHEX
	ldaa	#32
	int	F_PUTCHAR
	decb
	cmpb	#0
	bne	err1
	rts
	endp

fillbyte proc
loop	ldx	#fillram1
	int	F_PUTSTR
	int	F_PUTHEX
	ldx	RAM_START
loopw	staa	0,x
	inx
	cpx	RAM_END
	bne	loopw
	ldx	RAM_START
loopr	ldab	0,x
	cba
	bne	error
	inx
	cpx	RAM_END
	bne	loopr
	ldx	#okay
	int	F_PUTSTR
	rts
error	pshx
	ldx	#failed
	int	F_PUTSTR
	tba
	int	F_PUTHEX
	ldx	#failed1
	int	F_PUTSTR
	pulx
	ldab	#16
err1	ldaa	0,x
	int	F_PUTHEX
	ldaa	#32
	int	F_PUTCHAR
	decb
	cmpb	#0
	bne	err1
	rts
	endp

fillbyte_step proc
loop	ldx	#fillram1
	int	F_PUTSTR
	int	F_PUTHEX
	ldx	RAM_START
loopw	staa	0,x
	ldab	RAM_STEP
	abx
	cpx	RAM_END
	bne	loopw
	ldx	RAM_START
loopr	ldab	0,x
	cba
	bne	error
	ldab	RAM_STEP
	abx
	cpx	RAM_END
	bne	loopr
	ldx	#okay
	int	F_PUTSTR
	rts
error	pshx
	ldx	#failed
	int	F_PUTSTR
	tba
	int	F_PUTHEX
	ldx	#failed1
	int	F_PUTSTR
	pulx
	ldab	#16
err1	ldaa	0,x
	int	F_PUTHEX
	ldaa	#32
	int	F_PUTCHAR
	decb
	cmpb	#0
	bne	err1
	rts
	endp

hello	db	$0a, $0d, 'External Static RAM CHECK', $0a, $0d, 0
fillram1 db	'Fill RAM with byte ', 0
okay	db	' Okay', 10, 13, 0
failed	db	' Failed ($',0
failed1 db	')', 10, 13, 0

RAM_START	dw	0
RAM_END		dw	0
RAM_STEP	db	0
