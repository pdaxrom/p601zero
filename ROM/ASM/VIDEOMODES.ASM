;
; VPU test
;

;
; pyldin ints:
; int $12
; int $13
; int $14
; int $15
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	lds	#$afff
	ldx	#hello
	int	F_PUTSTR

	ldx	#kimscreen
	ldaa	#$3
	int	F_SETVIDEOMODE

	int	F_UART_IN

	ldx	#instr
	int	F_PUTSTR

	jmp	updcur

loop	int	F_UART_IN
	cmpa	#'1'
	beq	settext
	cmpa	#'2'
	beq	setgraf
	cmpa	#'3'
	beq	getvmode
	cmpa	#'9'
	beq	curincx
	cmpa	#'0'
	beq	curincy
	cmpa	#'4'
	bne	loop
	int	F_WARMRES
setgraf	ldx	#kimscreen
	ldaa	#3
	int	F_SETVIDEOMODE
	bra	updcur
settext	ldx	#textscreen
	ldaa	#$0
	int	F_SETVIDEOMODE
	bra	updcur

getvmode int	F_GETVIDEOMODE
	ldx	#int13txt
	int	F_PUTSTR
	int	F_GETVIDEOMODE
	pshx
	int	F_PUTHEX
	ldaa	#' '
	int	F_PUTCHAR
	pula
	int	F_PUTHEX
	pula
	int	F_PUTHEX
	bra	loop

curincx	inc	curx
	bra	updcur
curincy	inc	cury

updcur	ldaa	curx
	ldab	cury
	int	F_SETCURSOR

	ldx	#int14txt
	int	F_PUTSTR

	int	F_GETCURSOR
	pshx
	int	F_PUTHEX

	ldaa	#' '
	int	F_PUTCHAR

	tba
	int	F_PUTHEX

	ldaa	#' '
	int	F_PUTCHAR

	pula
	int	F_PUTHEX
	pula
	int	F_PUTHEX
	bra	loop

curx	db	0
cury	db	0

hello	db	$0a, $0d, 'VIDEOMODES TEST', $0a, $0d, 0
instr	db	'1 - text mode, 2 - graphics mode, 3- get video mode, 9 - inc cursor x, 0 - inc cursor y, 4 - exit', 0
int13txt db	10, 13, 'Video mode and address ', 0
int14txt db	10, 13, 'X, Y and address ', 0
byebye	db	10,13,'Bye!',10,13,0

kimscreen
	include	KIM.INC
textscreen
	db	'VPU TEXT MODE! vpu text mode! Hello! HELLO!'
