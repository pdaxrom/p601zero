;
; VPU test
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

VPU_ADDR equ	$E600
VPU_DATA equ	$E602
VPU_CFG  equ	$E603
VPU_STAT equ	$E603
VPU_HSCN equ	$E604
VPU_VSCN equ	$E606

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
	ldaa	VPU_STAT
	bita	#VPU_IRQ
	bne	next
exit	rti
next	bita	#VPU_VBL
	bne	exit

	ldx	#11
	stx	VPU_ADDR

	ldab	#40

	ldx	VPU_VSCN
	cpx	#60
	blt	exit
	cpx	#260
	blt	outline
black	ldaa	#$00
loop2	staa	VPU_DATA
	decb
	bne	loop2
	ldx	SCR_START
	stx	SCR_COUNT
	rti

outline	ldx	SCR_COUNT
	ldaa	0,x
	staa	VPU_DATA
	ldaa	1,x
	staa	VPU_DATA
	ldaa	2,x
	staa	VPU_DATA
	ldaa	3,x
	staa	VPU_DATA
	ldaa	4,x
	staa	VPU_DATA
	ldaa	5,x
	staa	VPU_DATA
	ldaa	6,x
	staa	VPU_DATA
	ldaa	7,x
	staa	VPU_DATA
	ldaa	8,x
	staa	VPU_DATA
	ldaa	9,x
	staa	VPU_DATA
	ldaa	10,x
	staa	VPU_DATA
	ldaa	11,x
	staa	VPU_DATA
	ldaa	12,x
	staa	VPU_DATA
	ldaa	13,x
	staa	VPU_DATA
	ldaa	14,x
	staa	VPU_DATA
	ldaa	15,x
	staa	VPU_DATA
	ldaa	16,x
	staa	VPU_DATA
	ldaa	17,x
	staa	VPU_DATA
	ldaa	18,x
	staa	VPU_DATA
	ldaa	19,x
	staa	VPU_DATA
	ldaa	20,x
	staa	VPU_DATA
	ldaa	21,x
	staa	VPU_DATA
	ldaa	22,x
	staa	VPU_DATA
	ldaa	23,x
	staa	VPU_DATA
	ldaa	24,x
	staa	VPU_DATA
	ldaa	25,x
	staa	VPU_DATA
	ldaa	26,x
	staa	VPU_DATA
	ldaa	27,x
	staa	VPU_DATA
	ldaa	28,x
	staa	VPU_DATA
	ldaa	29,x
	staa	VPU_DATA
	ldaa	30,x
	staa	VPU_DATA
	ldaa	31,x
	staa	VPU_DATA
	ldaa	32,x
	staa	VPU_DATA
	ldaa	33,x
	staa	VPU_DATA
	ldaa	34,x
	staa	VPU_DATA
	ldaa	35,x
	staa	VPU_DATA
	ldaa	36,x
	staa	VPU_DATA
	ldaa	37,x
	staa	VPU_DATA
	ldaa	38,x
	staa	VPU_DATA
	ldaa	39,x
	staa	VPU_DATA
	abx
	stx	SCR_COUNT
	rti
	endp

SCR_START dw 0
SCR_COUNT dw 0

OLD_VIRQ dw	0

hello	db	$0a, $0d, 'VPU TEST', $0a, $0d, 0

	ds $1000-*
kimscreen
	include	KIM.INC
