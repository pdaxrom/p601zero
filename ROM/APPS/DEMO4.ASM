	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	jsr	F_UART_PUTS

	ldx	#$1000
	stx	$e600
;	stx	$e60a

	ldaa	#14
	staa	$e602
	ldaa	#54
	staa	$e603

	ldx	#$1000

	ldab	#41
	ldaa	#$ff
loop	staa	0,x
	inx
	decb
	cmpb	#0
	bne	loop

	jmp	F_RESET

hello	db	$0a, $0d, 'VRAM CHECK', $0a, $0d, 0
