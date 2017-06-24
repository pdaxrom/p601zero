;
; UART BOOTROM for BLACK EYES 601 Zero
; (c) sashz <sashz@pdaXrom.org>, 2017
;

		include DEVMAP.INC

;
; BootROM variables and functions
;

		include BOOTROM.INC

		include FAT16.INC

		org	$C000
		dw	$A55A
		db	'Z/KERNEL'
		jmp	p601_init
		jmp	p601_monitor
		db	0		; No Pyldin 601 swi calls here
p601_init	rts
p601_monitor	rts
init		ldx	#title
		int	F_UART_PUTS
		int	F_WARMRES

title		db	'Z/pdaXrom kernel started!', 10, 13, 0

		checksum
		ds	$DFFE-*,$FF
		dw	init
