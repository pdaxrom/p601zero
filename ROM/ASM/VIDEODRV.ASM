;
; VPU test
;

	include ../DEVMAP.INC

	include ../BOOTROM.INC

GRSCR_START	equ	$A000

	org $e000

	ldx	#hello
	int	F_PUTSTR

	ldx	#GRSCR_START
	stx	SCR_START

; Set graphics mode
	ldaa	VPU_CFG
	oraa	#VPU_GRF
	staa	VPU_CFG

; Set start line
	ldx	#60
	stx	VPU_VSTART

; Set end line
	ldx	#260
	stx	VPU_VEND

; Framebuffer position
	ldx	#11
	stx	VPU_HSTART

; Set DMA address
	ldx	SCR_START
	stx	VPU_VADDR

; let start DMA engine
	ldaa	#40
	staa	VPU_HSIZE

	ldx	#byebye
	int	F_PUTSTR

	int	F_WARMRES

SCR_START dw 0
SCR_COUNT dw 0

hello	db	$0a, $0d, 'Graphics screen initing... ', 0
byebye	db	'done!',10,13,0
