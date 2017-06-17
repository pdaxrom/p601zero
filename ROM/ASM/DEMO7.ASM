;
; VCRT text mode
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	lds	#$afff
	ldx	#hello
	jsr	F_UART_PUTS

;    bra	test

	bsr	dumpregs

	clrb
	ldx	#videotbl
crtloop ldaa	x
	stab	$e600
	staa	$e601
	inx
	incb
	cmpb	#16
	bne	crtloop

	ldx	#$e000
clear	clr	0,x
	inx
	cpx	#$e600
	bne	clear

test
;	ldaa	#$ff
	ldx	#$e000
;	staa	40,x

;	jmp	F_RESET

loop	jsr	F_UART_IN
	tab
	jsr	F_UART_OUTHEX
	psha
 nop
 nop
 nop
 nop
 nop
 nop
 nop
 nop
;	ldaa	#10
;	jsr	F_UART_OUT
;	ldaa	#13
;	jsr	F_UART_OUT
	pshx
 nop
 nop
 nop
 nop
 nop
 nop
 nop
 nop
	pula
	jsr	F_UART_OUTHEX
 nop
 nop
 nop
 nop
 nop
 nop
 nop
 nop
	pula
 nop
 nop
	jsr	F_UART_OUTHEX
;	ldaa	#10
;	jsr	F_UART_OUT
;	ldaa	#13
;	jsr	F_UART_OUT
 nop
 nop
 nop
 nop
 nop
 nop
 nop
 nop
	pula
	jsr	F_UART_OUTHEX
	staa	0,x
	ldaa	0,x
	jsr	F_UART_OUTHEX
	ldaa	#10
	jsr	F_UART_OUT
	ldaa	#13
	jsr	F_UART_OUT
	inx
	tba
;	jsr	F_UART_OUTHEX
	cmpa	#27
	bne	loop

	bsr	dumpregs

	jmp	F_RESET

dumpregs proc
	clrb
loop	ldx	#regs
	jsr	F_UART_PUTS
	tba
	jsr	F_UART_OUTHEX
	ldaa	#32
	jsr	F_UART_OUT
	stab	$e600
	ldaa	$e601
	jsr	F_UART_OUTHEX
	incb
	cmpb	#16
	bne	loop
	rts
	endp

videotbl	db	63,40,47,5
		db	38,0,25,31
		db	0,7, $20,7
		dw	$e000,$e000

hello	db	$0a, $0d, 'VRAM CHECK', $0a, $0d, 0
regs	db	10, 13, '6845 reg ', 0
