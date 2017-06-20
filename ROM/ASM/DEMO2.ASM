	include ../DEVMAP.INC

	include ../BOOTROM.INC

swipag	equ	$F580
swivec	equ	$F600

	org $100

	ldx	#swipag
clrswi	clr	0,x
	inx
	cpx	#swipag+$280
	bne	clrswi

	ldx	#dumpic
	stx	swivec
	ldx	#haha
	stx	swivec+2
	ldx	#showregs
	stx	swivec+4

	ldx	#swihndl
	stx	VSWI

	ldx	#hello
	jsr	F_UART_PUTS


	int	$01

	ldaa	#$01
	ldab	#$02
	ldx	#$0304

	int	$02

	pshx
	jsr	F_UART_OUTHEX
	tba
	jsr	F_UART_OUTHEX
	pula
	jsr	F_UART_OUTHEX
	pula
	jsr	F_UART_OUTHEX

	ldx	#okay
	jsr	F_UART_PUTS

	jmp	F_RESET


swihndl proc
	tsx
	ldd	5,x
	addd	#1
	std	5,x
	xgdx
	dex
	ldaa	0,x

	ldab	RAMPAGE_SEL
	pshb
	tab
	ldx	#swipag
	lsrb
	abx
	ldab	0,x
	bcc	swih1
	lsrb
	lsrb
	lsrb
	lsrb
swih1	andb	#$0F
	stab	RAMPAGE_SEL

	tab
	ldx	#swivec
	abx
	abx
	ldx	0,x
	cpx	#0
	beq	exit
	xgdx
	ldx	#swiret
	pshx
	pshb
	psha

	tsx
	ldaa	5,x
	tap
	ldab	6,x
	ldaa	7,x
	ldx	8,x
	rts

swiret	pshx
	tsx
	stab	4,x
	staa	5,x
	pula
	staa	6,x
	pula
	staa	7,x
exit	pulb
	stab	RAMPAGE_SEL

	tsx
	jsr	dumpic

	rti
	endp

dumpic	proc
	ldab	#7
loop	ldaa	0,x		; CC
	jsr	F_UART_OUTHEX
	ldaa	#' '
	jsr	F_UART_OUT
	inx
	decb
	bne	loop

	tsx
	inx
	pshx

	pula			; SPH
	jsr	F_UART_OUTHEX
	pula			; SPL
	jsr	F_UART_OUTHEX
	ldaa	#10
	jsr	F_UART_OUT
	ldaa	#13
	jsr	F_UART_OUT
	rts
	endp

haha	proc
	ldx	#htxt
	jsr	F_UART_PUTS
	rts
htxt	db	10,13,'HAHAHAHA!!!',10,13,0
	endp

showregs proc
	pshx
	jsr	F_UART_OUTHEX
	tba
	jsr	F_UART_OUTHEX
	pula
	jsr	F_UART_OUTHEX
	pula
	jsr	F_UART_OUTHEX


	ldaa	#$81
	ldab	#$82
	ldx	#$BABE

	rts
	endp

hello	db	$0a, $0d, 'Hello World!!!', $0a, $0d, 0
okay	db	10, 13, 'Bye!!!', 0
