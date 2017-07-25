;
; ram pages check
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

	org $100

	ldx	#hello
	int	F_PUTSTR

	ldaa	RAMPAGE_CTL
	anda	#($FF ^ RAMPAGE_LOCK)
	staa	RAMPAGE_CTL

	clra
loop	staa	RAMPAGE_SEL
	staa	$c000
	tab
	addb	#$10
	stab	$d000
	inca
	cmpa	#16
	bne	loop

	bsr	readpages

	ldx	#hello1
	int	F_PUTSTR

	ldaa	RAMPAGE_CTL
	oraa	#RAMPAGE_LOCK
	staa	RAMPAGE_CTL

	clra
loop2	staa	RAMPAGE_SEL
	tab
	negb
	stab	$c000
	addb	#$10
	stab	$d000
	inca
	cmpa	#16
	bne	loop2

	bsr	readpages

	int	F_WARMRES

readpages proc
	clrb
loop	stab	RAMPAGE_SEL
	ldx	#page
	int	F_PUTSTR
	tba
	int	F_PUTHEX
	ldaa	#32
	int	F_PUTCHAR
	ldaa	$c000
	int	F_PUTHEX
	ldaa	#32
	int	F_PUTCHAR
	ldaa	$d000
	int	F_PUTHEX
	incb
	cmpb	#16
	bne	loop
	rts
	endp

hello	db	10, 13, 'RAMPAGES CHECK', 0
hello1	db	10, 13, 'RAMPAGES CHECK LOCK', 0
page	db	10, 13, 'Page ', 0
