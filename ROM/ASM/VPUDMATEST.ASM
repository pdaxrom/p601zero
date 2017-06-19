;
; VPU test
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	lds	#$afff
	ldx	#hello
	jsr	F_UART_PUTS

	ldx	#kimscreen
	ldaa	#1
	jsr	setvideomode

loop	jsr	F_UART_IN
	cmpa	#'1'
	beq	settext
	cmpa	#'2'
	beq	setgraf
	cmpa	#'3'
	bne	loop
	jmp	F_RESET
setgraf	ldx	#kimscreen
	ldaa	#1
	jsr	setvideomode
	bra	loop
settext	ldx	#textscreen
	ldaa	#0
	jsr	setvideomode
	bra	loop

; Set video mode
; A = 0 - text, 1 - graphics, $FF - disable
; X = Video address
setvideomode proc
SCR_START	equ	VPU_UREG1
	pshx
	psha
	pshb
	tab

; Disable video interrupt
	ldaa	VPU_CFG
	anda	#($FF^VPU_IEN) ; $BF
	staa	VPU_CFG

	cmpb	#$FF
	beq	exit

	stx	SCR_START

	cmpb	#0
	bne	initgrf

	ldx	#videotxthndl

; Set text mode
	ldaa	VPU_CFG
	anda	#($FF^VPU_GRF); $DF
	staa	VPU_CFG

; Set char line address
	ldaa	#7
	staa	VPU_CLINE

	bra	next

initgrf	ldx	#videohndl

; Set graphics mode
	ldaa	VPU_CFG
	oraa	#VPU_GRF
	staa	VPU_CFG

; Set video interrupt handler
next	stx	VNMI

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

; Enable video interrupts
	ldaa	VPU_CFG
	oraa	#VPU_IEN
	staa	VPU_CFG

exit	pulb
	pula
	pulx
	rts
	endp

videohndl proc
	sei
	ldaa	VPU_STAT
	bita	#VPU_IRQ
	beq	exit
	bita	#VPU_SVL
	beq	blank

; let start DMA engine
	ldaa	#40
	staa	VPU_VSIZE

exit	rti

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

videotxthndl proc
	sei
	ldaa	VPU_STAT
	bita	#VPU_IRQ
	beq	exit
	bita	#VPU_SVL
	beq	blank

	ldaa	VPU_CLINE
	inca
	anda	#$07
	staa	VPU_CLINE
	bne	exit

; let start DMA engine
	ldaa	#40
	staa	VPU_VSIZE

exit	rti

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
	ldaa	#7
	staa	VPU_CLINE
	rti
	endp

blackline db 0

OLD_VIRQ dw	0

hello	db	$0a, $0d, 'VPU TEST', $0a, $0d, 0
byebye	db	10,13,'Bye!',10,13,0

kimscreen
	include	KIM.INC
textscreen
	db	'VPU TEXT MODE! vpu text mode! Hello! HELLO!'
