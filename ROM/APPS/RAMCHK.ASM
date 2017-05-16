	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $8000

	ldx	#hello
	jsr	F_UART_PUTS

;	ldaa	#$aa
;	staa	$8000
;	staa	$8001
;	staa	$8002
;	staa	$8003

	ldaa	#$00
	staa	$1000
	inca
	staa	$1001
	inca
	staa	$1002
	inca
	staa	$1003
	inca
	staa	$1004
	inca
	staa	$1005
	inca
	staa	$1006
	inca
	staa	$1007

	ldx	#$1000
loop
;	staa	0,x
	ldaa	0,x
	staa	LED_HEX
	jsr	F_UART_OUTHEX

	inx
	cpx	#$1010
	bne	loop


	jmp	F_RESET

hello	db	$0a, $0d, 'External Static RAM CHECK!', $0a, $0d, 0
