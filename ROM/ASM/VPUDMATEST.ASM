;
; VPU test
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	lds	#$afff
	ldx	#hello
	int	F_UART_PUTS

	ldx	#kimscreen
	ldaa	#1
	jsr	setvideomode

loop	int	F_UART_IN
	cmpa	#'1'
	beq	settext
	cmpa	#'2'
	beq	setgraf
	cmpa	#'9'
	beq	cinc
	cmpa	#'0'
	beq	cdec
	cmpa	#'3'
	bne	loop
	int	F_WARMRES
setgraf	ldx	#kimscreen
	ldaa	#1
	jsr	setvideomode

	ldaa	curx
	ldab	cury
	jsr	setcursor

	bra	loop
settext	ldx	#textscreen
	ldaa	#0
	jsr	setvideomode

update	ldaa	curx
	ldab	cury
	jsr	setcursor

	bra	loop

cinc	inc	curx
	bra	update
cdec	inc	cury
	bra	update

curx	db	0
cury	db	0

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
next	stx	VEC_NMI_ADDR

; Set start line
	ldx	#60
	stx	VPU_VSTART

; Set end line
	ldx	#260
	stx	VPU_VEND

; Set DMA step
	ldaa	#0
	staa	VPU_VSTEP
	psha
; Clear screen
	ldx	#0
	stx	VPU_ADDR
	tsx
	stx	VPU_VADDR
	pula

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
	bne	exit

; let start DMA engine
	ldaa	#40
	staa	VPU_VSIZE

exit	rti

blank	bita	#VPU_EVL
	beq	exit

	ldx	SCR_START
	stx	VPU_VADDR
	ldaa	#7
	staa	VPU_CLINE
	rti
	endp

setcursor proc
	pshx
	psha
	adda	#11
	inca
	staa	VPU_CPOS
	clra
	lsld
	lsld
	lsld
	ldx	#60
	pshx
	tsx
	addd	0,x
	pulx
	std	VPU_CSTART
	addd	#7
	std	VPU_CEND

	ldaa	VPU_CFG
	oraa	#VPU_CEN
	oraa	#VPU_CIN
;	anda	#($FF ^ VPU_CIN)
	staa	VPU_CFG

	pula
	pulx
	rts
	endp

hello	db	$0a, $0d, 'VPU TEST', $0a, $0d, 0
byebye	db	10,13,'Bye!',10,13,0

	ds	$1000-*

kimscreen
	include	KIM.INC
textscreen
	db	'VPU TEXT MODE! vpu text mode! Hello! HELLO!'
