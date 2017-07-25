;
; VPU test
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	lds	#$afff
	ldx	#hello
	int	F_PUTSTR

	ldx	#kimscreen
	ldaa	#1
	jsr	setvideomode

	bra	update

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
	pshx
	psha
	pshb
	tab

; Framebuffer address
	stx	VPU_VADDR

	cmpb	#0
	bne	initgrf

; Set text mode
	ldaa	VPU_CFG
	anda	#($FF^VPU_GRF); $DF
	staa	VPU_CFG

	bra	next

; Set graphics mode
initgrf	ldaa	VPU_CFG
	oraa	#VPU_GRF
	staa	VPU_CFG

; Set start line
next	ldx	#60
	stx	VPU_VSTART

; Set end line
	ldx	#260
	stx	VPU_VEND

; Framebuffer position
	ldaa	#11
	staa	VPU_HSTART

; let start DMA engine
	ldaa	#40
	staa	VPU_HSIZE

exit	pulb
	pula
	pulx
	rts
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
