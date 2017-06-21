	include	../DEVMAP.INC
	include	../BOOTROM.INC

QZEXIT	proc
	int	F_WARMRES
	endp

QZGETC	proc
	int	F_UART_IN
	rts
	endp

QZPUTC	proc
	tsx
	ldaa	3,x
	int	F_UART_OUT
	rts
	endp

QZPUTHEX proc
	tsx
	ldaa	3,x
	int	F_UART_OUTHEX
	rts
	endp

QZPUTHEX16 proc
	tsx
	ldaa	2,x
	int	F_UART_OUTHEX
	ldaa	3,x
	int	F_UART_OUTHEX
	rts
	endp

QZPUTS	proc
	tsx
	ldx	2,x
	int	F_UART_PUTS
	rts
	endp
