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
VPU_VADDR equ	$E60C
VPU_VSTEP equ	$E60E
VPU_VSIZE equ	$E60F

VPU_HSN  equ	$01
VPU_VBL  equ	$02
VPU_IEN  equ	$40
VPU_IRQ  equ	$80

	org $100

	lds	#$afff
	ldx	#hello
	jsr	F_UART_PUTS

	ldx	#kimscreen
	stx	SCR_START

	sei

	ldx	#videohndl
	stx	VNMI

; Set DMA step
	ldaa	#0
	staa	VPU_VSTEP

; Clear screen
	ldx	#0
	stx	VPU_ADDR
	ldx	#blackline
	stx	VPU_VADDR
	ldaa	#64
	staa	VPU_VSIZE

; let start DMA engine
	nop
	nop

; Set DMA step
	ldaa	#1
	staa	VPU_VSTEP

; Enable IRQ
	ldaa	VPU_CFG
	oraa	#VPU_IEN
	staa	VPU_CFG

	cli

loop	ldaa	INPUT_SWKEYS
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
	bra	loop

but1txt	db	'Button 1 pressed!', 10, 13, 0
but2txt db	'Button 2 pressed!', 10, 13, 0
but3txt db	'Button 3 pressed!', 10, 13, 0

videohndl proc
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

	ldab	#40

	cpx	#260
	bge	black

outline	stab	VPU_VSIZE

; let start DMA engine
	nop
	nop

	rti

black	cpx	#261
	bge	exit

	ldaa	#0
	staa	VPU_VSTEP
	ldx	#blackline
	stx	VPU_VADDR
	stab	VPU_VSIZE

; let start DMA engine
	nop
	nop

	ldaa	#1
	staa	VPU_VSTEP
	ldx	SCR_START
	stx	VPU_VADDR
	rti
	endp

blackline db 0

SCR_START dw 0
SCR_COUNT dw 0

OLD_VIRQ dw	0

hello	db	$0a, $0d, 'VPU TEST', $0a, $0d, 0
byebye	db	10,13,'Bye!',10,13,0

kimscreen
	include	KIM.INC
