	include	../DEVMAP.INC
	include	../BOOTROM.INC

QZEXIT	proc
	jmp	F_RESET
	endp

QZGETC	proc
	jmp	F_UART_IN
	endp

QZPUTC	proc
	tsx
	ldaa	3,x
	jmp	F_UART_OUT
	endp

QZPUTHEX proc
	tsx
	ldaa	3,x
	jmp	F_UART_OUTHEX
	endp

QZPUTHEX16 proc
	tsx
	ldaa	2,x
	jsr	F_UART_OUTHEX
	ldaa	3,x
	jmp	F_UART_OUTHEX
	endp

QZPUTS	proc
	tsx
	ldx	2,x
	jmp	F_UART_PUTS
	endp
