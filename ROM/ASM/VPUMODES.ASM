;
; VPU test
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

;	lds	#$afff
	ldx	#hello
	int	F_PUTSTR

	ldx	#grfmode
	int	F_VPUCONFIG

	ldx	#instr
	int	F_PUTSTR
;	int	F_BPT
;	int	F_WARMRES

loop	int	F_UART_IN
	cmpa	#'1'
	beq	settext
	cmpa	#'2'
	beq	setgraf
	cmpa	#'3'
	bne	loop
	int	F_WARMRES
setgraf	ldx	#grfmode
	int	F_VPUCONFIG
	bra	loop
settext	ldx	#txtmode
	int	F_VPUCONFIG
	bra	loop

hello	db	$0a, $0d, 'VPU TEST', $0a, $0d, 0
instr	db	'1 - text mode, 2 - graphics mode, 3 - exit', 0
byebye	db	10,13,'Bye!',10,13,0

grfmode	dw	kimscreen
	db	40
	db	25
	db	11
	db	60
	db	$FF^VPU_GRF
	db	VPU_GRF

txtmode	dw	textscreen
	db	40
	db	25
	db	11
	db	60
	db	$FF^VPU_GRF
	db	0

kimscreen
	include	KIM.INC
textscreen
	db	'VPU TEXT MODE! vpu text mode! Hello! HELLO!'
