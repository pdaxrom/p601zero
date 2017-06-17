;
; VPU test
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

VPU_ADDR equ	$E600
VPU_DATA equ	$E602
VPU_HSCN equ	$E604
VPU_VSCN equ	$E606
VPU_CFG  equ	$E608
VPU_STAT equ	$E608

VPU_HSN  equ	$01
VPU_VBL  equ	$02
VPU_IEN  equ	$40
VPU_IRQ  equ	$80

	org $100

	lds	#$afff
	ldx	#hello
	jsr	F_UART_PUTS

;
;
start	clr	VPU_ADDR
	ldaa	#0
	staa	VPU_ADDR+1
	ldab	#64
	ldaa	#0
loop	staa	VPU_DATA
	decb
	bne	loop

	ldx	#kimscreen
	stx	SCR_START

	sei

	ldx	#videoirq
	stx	VIRQ

	ldaa	VPU_CFG
	oraa	#VPU_IEN
	staa	VPU_CFG

	cli

loop1	ldaa	INPUT_SWKEYS
	staa	LED_8BIT
	bita	#1
	beq	next
	ldx	#but1txt
	bra	print
next	bita	#2
	beq	next2
	ldx	#but2txt
	bra	print
next2	bita	#4
	beq	loop
	ldx	#but3txt
print	jsr	F_UART_PUTS
	bra	loop1

but1txt	db	'Button 1 pressed!', 10, 13, 0
but2txt db	'Button 2 pressed!', 10, 13, 0
but3txt db	'Button 3 pressed!', 10, 13, 0

videoirq proc
	sei
	ldaa	VPU_STAT
	bita	#VPU_IRQ
	bne	next
exit	rti
next	bita	#VPU_VBL
	bne	exit

	ldx	#11
	stx	VPU_ADDR


	ldx	VPU_VSCN
	cpx	#60
	blt	exit
	cpx	#260
	bge	black

	sts	STACK_PTR
	lds	SCR_COUNT
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	pulx
	stx	VPU_DATA
	sts	SCR_COUNT
	lds	STACK_PTR
	rti

black	ldx	#0
	ldab	#20
loop2	stx	VPU_DATA
	decb
	bne	loop2
	ldx	SCR_START
	dex
	stx	SCR_COUNT
	rti
	endp

STACK_PTR dw 0

SCR_START dw 0
SCR_COUNT dw 0

OLD_VIRQ dw	0

hello	db	$0a, $0d, 'VPU TEST', $0a, $0d, 0

	ds $1000-*
kimscreen
	include	KIM.INC
