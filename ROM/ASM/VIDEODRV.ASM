;
; VPU test
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

GRSCR_START	equ	$A000

	org $e000

	ldx	#hello
	jsr	F_UART_PUTS

	ldx	#GRSCR_START
	stx	SCR_START

	sei

	ldx	#videohndl
	stx	VNMI

; Set graphics mode
	ldaa	VPU_CFG
	oraa	#VPU_GRF
	staa	VPU_CFG

; Set start line
	ldx	#60
	stx	VPU_VSTART

; Set end line
	ldx	#260
	stx	VPU_VEND

; Set DMA step
	ldaa	#0
	staa	VPU_VSTEP

; Clear screen
	ldx	#0
	stx	VPU_ADDR
	ldx	#blackline
	stx	VPU_VADDR

; let start DMA engine
	ldaa	#64
	staa	VPU_VSIZE

; Set DMA step
	ldaa	#1
	staa	VPU_VSTEP

; Framebuffer position
	ldx	#11
	stx	VPU_ADDR

; Enable IRQ
	ldaa	VPU_CFG
	oraa	#VPU_IEN
	staa	VPU_CFG

	cli

	ldx	#byebye
	jsr	F_UART_PUTS

	jmp	F_RESET

videohndl proc
	sei
	ldaa	VPU_STAT
	bita	#VPU_IRQ
	bne	next
exit	rti
next	bita	#VPU_SVL
	beq	blank

; let start DMA engine
	ldaa	#40
	staa	VPU_VSIZE

	rti

blank	bita	#VPU_EVL
	beq	exit

	ldaa	#0
	staa	VPU_VSTEP
	ldx	#blackline
	stx	VPU_VADDR
; let start DMA engine
	ldaa	#40
	staa	VPU_VSIZE

	ldaa	#1
	staa	VPU_VSTEP
	ldx	SCR_START
	stx	VPU_VADDR
	rti
	endp

blackline db 0

SCR_START dw 0
SCR_COUNT dw 0

hello	db	$0a, $0d, 'Graphics screen initing... ', 0
byebye	db	'done!',10,13,0
