;
; VPU test
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	int	F_PUTSTR

	ldx	#textscreen
	ldaa	#$80
	int	$12

;	ldaa	#'$'
;	int	$22
;	int	$22

	ldx	#title
	bsr	putstr

	ldx	#byebye
	int	F_PUTSTR

	int	F_WARMRES

putstr	proc
	pshx
	psha
loop	ldaa	0,x
	beq	ret
	int	$22
	inx
	bra	loop
ret	pula
	pulx
	rts
	endp

hello	db	$0a, $0d, 'VIDEOMODES TEST', $0a, $0d, 0
byebye	db	10,13,'Bye!',10,13,0

title	db	'Hello world!', 10, 13, 'HAHA', $1e, 33, 33, '+', 0

textscreen
	db	'VPU TEXT MODE! vpu text mode! Hello! HELLO!'
