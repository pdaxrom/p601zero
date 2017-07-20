;
; BOOTROM for Z/pdaXrom
; (c) sashz <sashz@pdaXrom.org>, 2017
;

		include ../DEVMAP.INC

;
; BootROM variables and functions
;

		include ../BOOTROM.INC

;		include FAT16.INC

		org	$C000
		dw	$A55A
		db	'BIOS601 '
		jmp	p601_init
		jmp	p601_monitor
		db	0		; No Pyldin 601 swi calls here
p601_init	rts
p601_monitor	rts

brom_inc	include BROM601.MEM

init		ldx	#title
		int	F_UART_PUTS

;
; Move BROM601 to system bootrom shadow ram
;
		ldx	#$F800
		lds	#brom_inc
		des
copybrom	pula
		staa	0,x
		inx
		cpx	#0
		bne	copybrom


		int	F_WARMRES

title		db	'Starting BIOS601 system kernel.', 10, 13, 0

		checksum
		ds	$DFFE-*,$FF
		dw	init
