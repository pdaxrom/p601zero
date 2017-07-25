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

	ldaa	#$55
	ldab	#$AA
	bsr	seq2bytes
	ldaa	#$AA
	ldab	#$55
	bsr	seq2bytes
	ldaa	#$A5
	ldab	#$5A
	bsr	seq2bytes
	ldaa	#$5A
	ldab	#$A5
	bsr	seq2bytes

	ldx	#testseq
loop	ldaa	0,x
	ldab	1,x
	pshx
	bsr	seq2bytes
	pulx
	inx
	inx
	cpx	#testseqend
	bne	loop

	int	F_UART_IN

	int	F_WARMRES

seq2bytes proc
	staa	fbyte
	stab	sbyte
	ldx	#testn1
	int	F_PUTSTR
	int	F_PUTHEX
	ldx	#testn2
	int	F_PUTSTR
	tba
	int	F_PUTHEX
	ldx	#testn3
	int	F_PUTSTR
	ldx	RAM_START
write	ldaa	fbyte
	staa	0,x
	ldaa	sbyte
	staa	1,x
	inx
	inx
	cpx	RAM_END
	bne	write

	ldx	RAM_START
read	ldaa	0,x
	cmpa	fbyte
	bne	errorf
	ldaa	1,x
	cmpa	sbyte
	bne	errors
	inx
	inx
	cpx	RAM_END
	bne	read
	ldx	#okay
	int	F_PUTSTR
	rts
errorf	psha
	ldaa	fbyte
	bra	error
errors	psha
	ldaa	sbyte
error	pshx
	ldx	#expect
	int	F_PUTSTR
	int	F_PUTHEX
	ldx	#ataddr
	int	F_PUTSTR
	pula
	int	F_PUTHEX
	pula
	int	F_PUTHEX
	ldx	#butread
	int	F_PUTSTR
	pula
	int	F_PUTHEX
	rts
testn1	db	10, 13, 'Test RAM with $',0
testn2	db	' $', 0
testn3	db	' ... ', 0
expect	db	'Expected $', 0
ataddr	db	' at address $', 0
butread	db	' but read $', 0
okay	db	'done!',0
	endp

fbyte	db	0
sbyte	db	0

hello	db	10, 13, 'External RAM test', 0

testseq	db	$55,$AA,$AA,$55,$A5,$5A,$5A,$A5
	db	$00,$FF,$FF,$00,$F0,$0F,$0F,$F0
	db	$01,$80,$80,$01,$08,$10,$10,$08

	db	$c6, $eb, $42, $10, $6b, $9c, $be, $e4, $4a, $f0, $75, $06, $79, $16, $6a, $6d
	db	$51, $d1, $18, $50, $f3, $2c, $ab, $06, $b4, $d6, $76, $fc, $4f, $f5, $37, $6a
	db	$ef, $ea, $b5, $06, $ee, $f1, $39, $ba, $cd, $5d, $dd, $0d, $f6, $b9, $5d, $2f
	db	$39, $a8, $cc, $18, $37, $ed, $0b, $b3, $13, $18, $e2, $fd, $1c, $56, $f5, $9d
	db	$a4, $9d, $fe, $63, $40, $4d, $95, $cd, $9d, $15, $0b, $c2, $90, $9f, $32, $ff
	db	$c9, $d7, $f5, $dc, $f9, $25, $22, $09, $fd, $2e, $ef, $ef, $d9, $6c, $f1, $dc
	db	$a1, $1a, $cf, $57, $c3, $80, $4f, $8d, $37, $3a, $80, $a1, $c6, $94, $0f, $e1
	db	$fa, $34, $57, $ea, $b4, $a1, $9b, $76, $6c, $65, $82, $f2, $54, $c9, $03, $d5
	db	$63, $d2, $43, $b9, $e9, $7e, $a7, $2e, $1c, $82, $31, $b5, $06, $d9, $54, $1d
	db	$57, $2d, $b8, $84, $e7, $df, $32, $0c, $19, $bd, $e5, $c5, $9a, $62, $b0, $a7
	db	$f3, $06, $7a, $4f, $19, $66, $67, $0b, $24, $ca, $70, $ad, $c5, $b3, $6b, $34
	db	$d4, $ff, $21, $62, $be, $9c, $b8, $22, $7e, $71, $07, $9e, $60, $28, $87, $b3
	db	$af, $7c, $35, $ae, $ab, $40, $f4, $eb, $0c, $d0, $7e, $29, $1e, $d9, $5a, $8e
	db	$9b, $a4, $2b, $ef, $32, $c5, $a8, $df, $51, $61, $e5, $14, $4c, $54, $26, $80
	db	$5b, $77, $03, $6b, $27, $3c, $0c, $19, $e6, $2d, $a8, $70, $ca, $aa, $90, $43
	db	$f0, $a6, $b0, $77, $21, $4e, $c0, $31, $7d, $72, $86, $e2, $d2, $e6, $84, $20
testseqend

RAM_START	dw	0
RAM_END		dw	0
