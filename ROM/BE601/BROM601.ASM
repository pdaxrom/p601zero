; ***********************************************************
; *							    *
; *	      ОПЕРАЦИОННА СИСТЕМА    U n i D O S	    *
; *	    за персонален микрокомпютър ПЪЛДИН 601 A	    *
; *							    *
; *    Copyright (C) 1988  НИПЛ "Програмно осигуряване"     *
; *							    *
; *		 (C) 1988  Иво Найденов НЕНОВ		    *
; *		 (C) 1988  Орлин Димитров ШОПОВ 	    *
; *							    *
; ***********************************************************
; *							    *
; *		  Basic Input/Output System		    *
; *		  Version 2.50 / 01-Mar-1990		    *
; *							    *
; ***********************************************************
		list	off

; ПРЕДУПРЕЖДЕНИЕ:
; Текста на операционната система се дава само за справка.
; Всяко директно обръщение към кода или модифициране на
; променливите на операционната система нарушава концепцията
; за съвместимост с различни версии. НИПЛ "Програмно осигуряване"
; си запазва правото да прави промени в кода и променливите на
; операционната система с цел подобрение на функционирането.
; Не се поема никаква отговорност за несъвместимост на програмни
; продукти, неспазили протокола за използване на операционната
; система с бъдещи версии.
; Обръщенията към операционната система следва да се извършват
; по протокола описан в ръководството за потребителя.

;-----------------------------------------------------------

		include ../devmap.inc

		include memory.inc

;---------------
; RAM work area locations:
swihndl_x	equ	2

		list	on
		section $ED50

;---------------------------- Keyboard ---------------------
kbd_temp	ds	2

;---------------------------- WriteChar --------------------
curaddr 	ds	2
altaddr 	ds	2
queuelen	ds	1
queueptr	ds	2
queuebuf	ds	3
scrtmp		ds	1
scrtmpx 	ds	2
putchar_x	ds	2

;---------------------------- Floppy -----------------------
recalib_flg	ds	1
mcounter	ds	1
tc		ds	1
olddrive	ds	1
track_A 	ds	1
track_B 	ds	1
drive		ds	1
track		ds	1
head		ds	1
sector		ds	1
buffer		ds	2
retcode 	ds	1
headdrive	ds	1
transfer_buff	ds	9
counter 	ds	2
retry		ds	1
double_step	ds	1

;---------------------------- Pseudo RS --------------------
allcap		ds	1

;---------------------------- Getline ----------------------
maxb		ds	1

		error	(*-1)/$ED80
		ends
		list	off

;***********************************************************

		org	$F800
		int	$30		;call monitor
		rts
; FIXME
; WTF?
;		jmp	putc

;-----------------------------------------------------------

reshndl 	proc			; драйвер за обработка на RESET
		sei			; забраняване на прекъсванията

;
; FIXME
; Peripheral init here
;

; FIMXME
; video init here
; ---------------

; ---------------

		ldx	#swipag 	; нулиране на таблицата с адресите
reshndl1	clr	0,x		; на интеръптите и страниците им
		inx
		cpx	#swipag+$280
		bne	reshndl1
		ldab	#$70		;установяване на интеръпти 00-37
		lds	#restbl-1
		ldx	#swivec
reshndl2	pula
		staa	0,x
		inx
		decb
		bne	reshndl2

		ldx	#$a55a
		cpx	resmagic
		beq	warm
		stx	resmagic

		ldx	#lowerram
ramtest3	clr	0,x		; нулиране на оперативната памет
		inx
		cpx	#upperram-$80
		bne	ramtest3

		ldx	#0
		stx	hundreds
		stx	minutes
		ldx	#$101
		stx	day
		ldx	#1989
		stx	year
warm
		clr	RAMPAGE_SEL 	; изключване на страничния ROM
		clr	indos		; изчистване на флага
		clr	equipment	; изчистване на флага
		clr	configuration	; флагове за флопитата

;		clr	fdcslct
;		inc	fdcslct

;		ldx	#contbl
;		stx	conparms
;		ldx	cur_replace,x
;		stx	cursor_start
;		clr	insert_mode
;		clr	macroflg	; макро клавитура
;		ldx	#0
;		stx	macro_def_ptr

; FIXME
; fddtable?
;		ldx	#fddtbl
;		stx	fddparms

;		ldx	#kbd_buffer
;		stx	kbd_store
;		stx	kbd_load
;		ldaa	#$60
;		staa	cursor_blink

		lds	#upperram

;		clra			; инициализация на видео режима
;		clrb
;		int	$12

;		ldx	#title		; името на компютъра
;		int	$23

;		ldaa	#$80
;		int	$17

;		ldaa	#$41
;		ldx	#mbrsec
;		int	$17

;		ldx	$02fe		; MBR signature
;		cpx	#$55aa
;		bne	nombrsig
;		jsr	$100		; call bootcode

nombrsig
		ldab	#8		; проверка на страничните ROM
romloop 	stab	RAMPAGE_SEL
		ldx	#$a55a		; за 2764 и 27128 първа част
		bitb	#%00000100
		beq	romt0
		ldx	#$5aa5		; за 27128 втора част
romt0		cpx	romstart
		bne	nextrom

		ldx	#romstart	; контролна сума на ROM
		clra
romloop1	adda	0,x
		inx
		cpx	#romstart+$2000
		bne	romloop1
		tsta
		bne	nextrom
		pshb

		ldx	#romstart+$10	; закачане на интеръпт драйверите
romtl		stx	x1		; от страничните ROM
		ldaa	0,x
		beq	romte
		ldab	RAMPAGE_SEL
		ldx	1,x
		int	$2f
		ldx	x1
		inx
		inx
		inx
		bra	romtl
romte
		jsr	romstart+$a	; инициализация на страничните ROM
		pulb
nextrom 	incb
		cmpb	#$10
		bcs	romloop 	;<
		clr	RAMPAGE_SEL

		ldx	#$F000
		clra
mainrom 	adda	x
		inx
		bne	mainrom
		tsta
		beq	mainrom_ok
		int	$00
mainrom_ok

;		ldab	#2		; init printer port
;		int	$26

;		ldab	#4
;		ldaa	#%100110
;		int	$27

		cli
;		ldaa	fdcstat
;		anda	#%11000000
;		cmpa	#%10000000
;		bne	nofloppy	;no floppy

		ldaa	#$80		; initialize
		int	$17		; reset FDC

;
; FIXME
;Bootsector
		ldx	#mbrsec		; инициализация на флопи-контролера
		ldaa	#$41		; четене на цилиндър 0, глава 0,
		int	$17		; сектор 1
		tsta
		bne	nofloppy
		ldx	$2fe		; проверка за принадлежност
		cpx	#$a55a
		bne	nofloppy
		jsr	$150
nofloppy
resetloop	int	$01		; край по RESET вектора
		bra	resetloop

		endp
;---------------------------------------
inthandlers	proc
		global	nmihndl, irqhndl

nmihndl 				; драйвр за NMI прекъсване
		ldab	swipag+1	;int02
		lsrb
		lsrb
		lsrb
		lsrb
		ldx	swivec+4	;int02
		bra	irqhndl1
;---------------
irqhndl
;		ldab	swipag+4	;int09
;		ldx	swivec+18	;int09
;		tst	piacra		;клавитурата ли е ?
;		bmi	irqhndl1	;да
;		ldab	swipag+1	;int03
;		ldx	swivec+6	;int03
;		tst	piacrb		; драйвер за IRQ прекъсване и
;		bpl	irqhndl1	; 50 Hz
; FIXME
; VBL irq here
;		tst	piadrb
		ldab	swipag+2	;int05
		ldx	swivec+10	;int05
irqhndl1	ldaa	RAMPAGE_SEL 	; обща част на NMI и IRQ драйверите
		psha
		andb	#$0f
		beq	irqhndl2
		stab	RAMPAGE_SEL
irqhndl2	cpx	#0
		beq	irqhndl3
		jsr	0,x
irqhndl3	pula
		staa	RAMPAGE_SEL
		rti
		endp

;---------------------------------------
swihndl 	proc			; драйвер за обработка на SWI
		sei			; осигурява псевдо-инструкцията INT
		inc	indos		; ниво на вложеност
		tsx
		lds	5,x		; компенсиране на PC за номера на
		des			; интеръпта
		pula			; номер на интеръпта
		ins
		sts	5,x
		txs
		psha
		bsr	exchregs	; размяна на SWI променливите и стека
		pula			; номер на интеръпта
		ldab	RAMPAGE_SEL 	; текуща ROM страница
		pshb			; спасява се в стека

		tab			; извличане на страницата на интеръпта
		lsrb
		stab	swihndl_x+1
		ldab	#/swipag
		stab	swihndl_x
		ldx	swihndl_x
		ldab	swipag,x
		bcs	swihndl1	;odd-low
		lsrb
		lsrb
		lsrb
		lsrb
swihndl1	andb	#$0f
		beq	swihndl4
		stab	RAMPAGE_SEL
swihndl4
		ldab	#$77		;$ee/2
		asla			; извличане на адреса на интеръпта
		rolb
		staa	swihndl_x+1
		stab	swihndl_x
		ldx	swihndl_x
		ldaa	swivec+1,x
		ldab	swivec,x
		beq	swihndl2
		bsr	swihndl3	; изпълнение на интеръпта
swihndl2
		sei			; въстановяване след интеръпта
		pulb
		stab	RAMPAGE_SEL 	; предишната страница
		tsx
		bsr	exchregs	; размяна на регистрите и стека
		dec	indos		; ниво на вложеност
		rti

exchregs
		ldaa	1,x
		ldab	swib		; регистър B
		staa	swib
		stab	1,x

		ldaa	2,x
		ldab	swia		; регистър A
		staa	swia
		stab	2,x

		ldaa	3,x
		ldab	swix		; регистър X
		staa	swix
		stab	3,x

		ldaa	4,x
		ldab	swix+1
		staa	swix+1
		stab	4,x

		ldaa	0,x		; регистър P
		ldab	swic
		staa	swic
		stab	0,x
		rts

swihndl3
		psha			; зареждане на регистрите и
		pshb			; изпълнение
		ldaa	swic
		tap
		ldx	swix
		ldab	swib
		ldaa	swia
		cli
		rts
		endp

;--------------------------------------
; RESET
;--------------------------------------
; FIXME
reset		proc
;loop0		ldaa	piacra
;		eora	#8
;		staa	piacra
;loop1		dex
;		bne	loop1
loop0		bra	loop0
		endp

;--------------------------------------
; TIME SUPPORT
;--------------------------------------
timer		proc
timer0		ldaa	hundreds
		inca
		inca
		cmpa	#100
		bcs	timer1
		clra
timer1
		staa	hundreds
		bne	exit

		int	$06		; 1 sec

		ldaa	seconds
		inca
		cmpa	#60
		bcs	timer2
		clra
timer2
		staa	seconds
		tsta
		bne	exit

		ldaa	minutes
		inca
		cmpa	#60
		bcs	timer3
		clra
timer3
		staa	minutes
		bne	exit

		ldaa	hours
		inca
		cmpa	#24
		bcs	timer4
		clra
timer4
		staa	hours
		bne	exit

		ldaa	day
		inca
		cmpa	#32
		bcs	timer5
		ldaa	#1
timer5
		staa	day
		cmpa	#1
		bne	exit

		ldaa	month
		inca
		cmpa	#13
		bcs	timer6
		ldaa	#1
timer6
		staa	month
		cmpa	#1
		bne	exit

		inc	year
exit
		rts

		endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Reset SPI/EXT devices
spi_reset proc
	psha
	ldaa	#SPI_INI
	oraa	SPI_REG
	staa	SPI_REG

	ldaa	SPI_REG
	anda	#($FF^SPI_RES)
	staa	SPI_REG

	ldaa	SPI_REG
	oraa	#SPI_RES
	staa	SPI_REG
	pula
	rts
	endp

; Check if spi in use
; Return:
; A 0 - not used, 1 - busy
;
spi_getstat proc
	pshx
	eora	#SPI_ALL
	psha
	anda	SPI_REG
	tsx
	cmpa	0,x
	pula
	beq	okay
	ldaa	#1
	bra	exit
okay	clra
exit	pulx
	rts
	endp

; Select spi device
; A Device
; B 1 Enable / 0 Disable
; Return:
; A status (0 - okay, 1 - busy)

spi_select proc
	psha
	bsr	spi_getstat
	tsta
	pula
	beq	select
	ldaa	#1
	rts
select	tstb
	beq	disable
	eora	#$FF
	anda	SPI_REG
	staa	SPI_REG
	bra	okay
disable	oraa	SPI_REG
	staa	SPI_REG
okay	clra
	rts
	endp

spi_write proc
	global	spi_read
	staa	SPI_DATA
loop	ldaa	SPI_STATUS
	bita	#SPI_READY
	beq	loop
	ldaa	SPI_DATA
	rts
spi_read ldaa	#$FF
	bra	spi_write
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
sd_show_cmd proc
	rts
	endp

sd_delay proc
	pshx
	ldx	#4000
loop	dex
	bne	loop
	pulx
	rts
	endp

sd_init_cmd0	db	$40, $00, $00, $00, $00, $95
sd_init_cmd1	db	$41, $00, $00, $00, $00, $FF
sd_init_cmd16	db	$50, $00, $00, $02, $00, $FF

sd_init	proc
	pshb
	pshx
	ldaa	#40
	staa	SPI_PRESCALER
	jsr	sd_disable
	ldab	#10
loop	jsr	spi_read
	decb
	bne	loop

	ldx	#sd_init_cmd0
	ldab	#10
loop1	jsr	sd_show_cmd
	cmpa	#$01
	beq	init2
	bsr	sd_delay
	decb
	bne	loop1
	ldaa	#1
	bra	exit

init2	ldx	#sd_init_cmd1
	ldab	#255
loop2	jsr	sd_show_cmd
	tsta
	beq	init3
	bsr	sd_delay
	decb
	bne	loop2
	ldaa	#2
	bra	exit

init3	ldx	#sd_init_cmd16
	jsr	sd_show_cmd
	clra
exit	pulx
	pulb
	bra	sd_disable
	endp

sd_command proc
	bsr	sd_disable
	bsr	sd_enable

	ldaa	0,x		; cmd
	jsr	spi_write
	ldaa	1,x		; arg
	jsr	spi_write
	ldaa	2,x		; arg
	jsr	spi_write
	ldaa	3,x		; arg
	jsr	spi_write
	ldaa	4,x		; arg
	jsr	spi_write
	ldaa	5,x		; CRC
	jsr	spi_write

	pshb
	ldab	#10
loop	jsr	spi_read
	cmpa	#$FF
	bne	exit
	decb
	bne	loop
exit	pulb
	rts
	endp

sd_enable proc
	pshx
	ldab	#1
wait	ldaa	#SPI_SD
	jsr	spi_select
	tsta
	bne	wait
	jsr	spi_read
	ldx	#5000
loop	jsr	spi_read
	cmpa	#$FF
	beq	exit
	jsr	sd_delay
	dex
	bne	loop
	bsr	sd_disable
	ldaa	#0
exit	inca
	pulx
	rts
	endp

sd_disable proc
	psha
	ldaa	#SPI_SD
	ldab	#0
	jsr	spi_select
	jsr	spi_read
	pula
	rts
	endp

;
; read sector from SD
;
; A = 0 - No error
;
; X - ptr to structure:
; ds 4 - sector
; ds 2 - buffer ptr
;
sd_read proc
	pshx
	pshb

;
; sector * 512
;
	ldaa	#$FF
	psha
	clra
	psha
	ldaa	3,x
	rola
	psha
	ldaa	2,x
	rola
	psha
	ldaa	1,x
	rola
	psha
	ldaa	#$51		; CMD17
	psha
	ldx	4,x		; buffer
	pshx
	tsx
	inx
	inx			; X to saved data for sd_command
	jsr	sd_show_cmd
	pulx

	tsta
	beq	next
	ldaa	#1
	bra	exit

next	ldab	#255
next1	jsr	spi_read
	cmpa	#$FF
	bne	next2
	jsr	sd_delay
	decb
	bne	next1
	ldaa	#2
	bra	exit
next2	cmpa	#$FE
	beq	next3
	ldaa	#3
	bra	exit
next3	bsr	rcvr
	bsr	rcvr
	jsr	spi_read
	jsr	spi_read
	ldaa	#0

exit	tsx
	ldab	#6
	abx
	txs
	bsr	sd_disable

	pulb
	pulx
	rts

rcvr	ldab	#0
rcvr1	jsr	spi_read
	staa	0,x
	inx
	decb
	bne	rcvr1
	rts
	endp

;
; write sector to SD
;
; A = 0 - No error
;
; X - ptr to structure:
; ds 4 - sector
; ds 2 - buffer ptr
;
sd_write proc
	pshx
	pshb

;
; sector * 512
;
	ldaa	#$FF
	psha
	clra
	psha
	ldaa	3,x
	rola
	psha
	ldaa	2,x
	rola
	psha
	ldaa	1,x
	rola
	psha
	ldaa	#$58		; CMD24
	psha
	ldx	4,x		; buffer
	pshx
	tsx
	inx
	inx			; X to saved data for sd_command
	jsr	sd_show_cmd
	pulx

	tsta
	beq	next
	ldaa	#1
	bra	exit

next	ldab	#255
next1	jsr	spi_read
	cmpa	#$FF
	beq	next2
	jsr	sd_delay
	decb
	bne	next1
	ldaa	#2
	bra	exit
next2	ldaa	#$FE
	jsr	spi_write
	bsr	xmit
	bsr	xmit
	jsr	spi_read
	jsr	spi_read
	jsr	spi_read
	anda	#$1F
	cmpa	#$05
	bne	next3
	ldaa	#0
	bra	exit
next3	ldaa	#3

exit	tsx
	ldab	#6
	abx
	txs
	jsr	sd_disable

	pulb
	pulx
	rts

xmit	ldab	#0
xmit1	ldaa	0,x
	jsr	spi_write
	inx
	decb
	bne	xmit1
	rts
	endp

sd_flush proc
	jsr	sd_enable
	tsta
	bne	exit
	jsr	sd_disable
exit	rts
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;---------------------------------------
; SERIAL SUPPORT
;---------------------------------------
rs232c		proc			; или серийния вход
		global	int18, int19

;baud - $7e- 1200bps
;	$3A- 2400bps
;	$18- 4800bps
;	$07- 9600bps
;bits - number of bits
;parity: $00 - even+1stop
;	 $FF - odd + 1stop
;	 $80 - no + 2stop
;A - byte
;Ret: Z=0 - parity error

int18		sei
		rts

int19		sei
		rts
		endp

;-----------------------------------------
; UNISGNED MULTIPLY
;-----------------------------------------
; BA = A * B
int28		proc
		mul
		staa	swib
		stab	swia
		rts
		endp

;-----------------------------------------
; UNSIGNED DIVISION
;-----------------------------------------
;Unsigned division 16b/16b = 16b, 16b
;
;x:= x div ba
;ba:= x mod ba
;ba = $FFFF - error: division by zero
;-----------------------------------------
int29		proc
		stx	x1		;delimo
		stab	x2		;delitel
		staa	x2+1		;delitel
		bne	ok
		tstb
		bne	ok
		coma
		comb
		bra	error
ok
		clra
		clrb
		ldx	#17
loop		rola
		rolb
		suba	x2+1
		sbcb	x2
		bcc	skip		;>=
		adda	x2+1
		adcb	x2
skip		rol	x1+1
		rol	x1
		dex
		bne	loop
		com	x1+1
		com	x1
		ldx	x1
error		jmp	rtswix
		endp

;-----------------------------------------
; ALLOCATE MEMORY
;-----------------------------------------
; ENTER:
; X - number of bytes
; B - allignment  0..8
;	2^B
;RETURN : X = 0   -   aloc. error
;	  X - pointer
;-----------------------------------------
int2A		proc
		sei
		cmpb	#9
		bcc	error
		stx	x1
		beq	exit		; 2.12 / 1-Nov-89
		tsx
		stx	x2
		ldaa	himem+1
		ldab	himem
		suba	x1+1
		sbcb	x1
		bcs	error
		staa	x1+1
		stab	x1

		ldab	swib
		ldaa	#$ff
loop1		tstb
		beq	exit_loop1
		asla
		decb
		bra	loop1
exit_loop1	anda	x1+1
		staa	x1+1
		ldab	x1
		suba	himem+1
		sbcb	himem
		adda	x2+1
		adcb	x2
		bcc	error		;!
		staa	x2+1
		stab	x2
		decb
		cmpb	lomem
		bne	differ1
		cmpa	lomem+1
differ1 	bcs	error
		ldx	x2
loop2		pula
		staa	x
		inx
		cpx	x1
		bne	loop2
		stx	himem
		ldx	x2
		txs
exit		ldx	himem
		stx	swix
		rts
error		ldx	#0
		stx	swix
		rts
		endp

;-----------------------------------------
; RELEASE MEMORY
;-----------------------------------------
; ENTER:
; X - pointer
;RETURN :
;	  X - size
;-----------------------------------------
int2B		proc
		sei
		stx	x1
		ldaa	x1+1
		ldab	x1
		cmpb	himem
		bne	differ1
		cmpa	himem+1
differ1 	bls	error
		cmpb	resident
		bne	differ2
		cmpa	resident+1
differ2 	bhi	error
		sts	x2
		txs
		ldx	himem
		bra	entry1
loop1		ldaa	x
		psha
entry1		dex
		cpx	x2
		bne	loop1
		ldaa	x1+1
		ldab	x1
		suba	himem+1
		sbcb	himem
		staa	swix+1
		stab	swix
		ldx	x1
		stx	himem
		rts
error		ldx	#0
		stx	swix
		rts
		endp


;---------------------------------------
; MARK RESIDENT
;---------------------------------------
int2c		proc
rsdnt		ldx	himem
		stx	resident
		rts
		endp

;-----------------------------------------
; MOVE MEMORY
;-----------------------------------------
; ENTER:
; X - pointer
;	X1 - src
;	X2 - dest
; BA - length
;RETURN : X - number of bytes
;-----------------------------------------
int2D		proc
		sei
		ldx	x
		stx	x2		;src_beg
		dex
		stx	x1		;src_end
		ldx	swix
		ldx	x, 2
		stx	x4		;dst_beg

		staa	swix+1
		stab	swix
		tsta
		bne	ok
		tstb
		beq	rts2
ok
		adda	x1+1
		adcb	x1
		staa	x1+1
		stab	x1

		sts	tmps
		ldaa	x1+1		;src end - извличане на параметрите
		ldab	x1		;	   на командата MOVE
		suba	x2+1		;src beg
		sbcb	x2
		adda	x4+1		;dst beg
		adcb	x4
		staa	x3+1		;dst end
		stab	x3

		ldaa	x4		; определяне на посоката на местене
		cmpa	x2		; на памет
		bne	move1
		ldaa	x4+1
		cmpa	x2+1
move1		bls	mvleft
mvright 				; местене надясно
		lds	x3
		ldx	x1
		inx
mvright1	dex
		ldaa	0,x
		psha
		cpx	x2
		bne	mvright1
		bra	mvend
mvleft					; местене наляво
		lds	x2
		ldx	x4
mvleft0 	des
		dex
mvleft1 	inx
		pula
		staa	0,x
		cpx	x3
		bne	mvleft1
mvend		lds	tmps
rts2		rts

		endp
;---------------------------------------
; GET INTERRUPT VECTOR
;---------------------------------------
int2e		proc			; получаване на интеръпт вектор
getvec
		sei
		tab
		lsrb
		stab	tmpx+1
		ldab	#/swipag
		stab	tmpx
		ldx	tmpx
		ldab	swipag,x
		bcs	getvec1 	;odd-low
		lsrb
		lsrb
		lsrb
		lsrb
getvec1 	andb	#$0f
		stab	swib
		ldab	#$77		;$ee/2
		asla
		rolb
		staa	tmpx+1
		stab	tmpx
		ldx	tmpx
		ldx	swivec,x
		stx	swix
		rts
		endp

;---------------------------------------
; SET INTERRUPT VECTOR
;---------------------------------------
int2f		proc
putvec					; задаване на интеръпт вектор
		sei
		sts	tmps
		txs
		ins
		staa	tmpb
		lsra
		staa	tmpx+1
		ldaa	#/swipag
		staa	tmpx
		ldx	tmpx
		ldaa	#$0f		;hi
		bcc	*+4
		ldaa	#$f0		;lo
		anda	swipag,x
		staa	tmpa
		tba			;RAMPAGE_SEL
		anda	#$0f
		bcs	*+6
		asla
		asla
		asla
		asla
		oraa	tmpa
		staa	swipag,x
		ldaa	#$77
		ldab	tmpb
		aslb
		rola
		stab	tmpx+1
		staa	tmpx
		ldx	tmpx
		sts	0,x
		lds	tmps
		rts
		endp

;---------------------------------------
; PRESERVE MEMORY	  enter: BA - size, exit: X - old lomem, BA - size
;---------------------------------------
int_35		proc
		sei
		ldx	lomem
		stx	swix
		sts	tmps
		dec	tmps
		adda	lomem+1
		adcb	lomem
		cmpb	tmps
		bne	check
		cmpa	tmps+1
check		bcc	check_bad	;>=
		stab	lomem
		staa	lomem+1
		rts
check_bad	clr	swib
		clr	swia
		rts
		endp

;---------------------------------------
; GET FREE MEMORY
;---------------------------------------
int_36		proc
		sei
		ldx	lomem
		sts	tmps
		ldaa	tmps+1
		ldab	tmps
		decb
		suba	lomem+1
		sbcb	lomem
		bcc	ok
		clrb
		clra
ok		jmp	rtswix
		endp

;---------------------------------------
; CHAIN INTERRUPT
;---------------------------------------
int_37		proc
		sei
		cpx	#0
		bne	ok
		ldx	#sysrts 	;force return
		stx	swix
		clrb			;don't change page
ok
		tsx
		stab	2,x		;corresponding page
		ldab	swix		;go to it via rts exit from this int
		ldaa	swix+1
		stab	8,x		;pc
		staa	9,x

		ldaa	3,x		;pass original ZP parms
		staa	swic
		ldab	4,x
		ldaa	5,x
		ldx	6,x
		jmp	rtswix

		endp

;---------------------------------------

restbl					; таблица с начални стойности на
					; интеръптите
		dw	reset		;00
		dw	reset		;01
		dw	0		;02
		dw	0		;03
		dw	0		;04
		dw	timer		;05
		dw	0		;06
		dw	0		;07
		dw	0		;08
		dw	0		;int09		;09	обслуживание прерывания с клавиатуры
		dw	0		;0a
		dw	0		;0b
		dw	0		;0c
		dw	upperram	;0d
		dw	lowerram	;0e
		dw	upperram	;0f
		dw	0		;int10		;	проверка клавиатуры
		dw	0		;int11		;	считывание клавиатуры
		dw	0		;int12		;	инициализация видеорежима
		dw	0		;int13		;	текущий видеорежим
		dw	0		;int14		;	текущее положение курсора
		dw	0		;int15		;	позиционирование курсора
		dw	0		;int16		;16	установка аттрибута
		dw	0		;int17		;17	управление дисководом
		dw	int18		;18
		dw	int19		;19
		dw	0		;1A
		dw	0		;1B
		dw	0		;1c
		dw	0		;1d
		dw	0		;1e
		dw	0		;1f
		dw	0		;int20		;	чтение символа с консоли
		dw	0		;int21		;	чтение строки с консоли
		dw	0		;int22		;	вывод символа на консоль
		dw	0		;int23		;	вывод строки на консоль
		dw	0		;24
		dw	0		;25
		dw	0		;int26		;26	управление принтером
		dw	0		;27
		dw	int28		;28
		dw	int29
		dw	int2a
		dw	int2b
		dw	int2c
		dw	int2d
		dw	int2e
		dw	int2f
		dw	0		;30  - mon
		dw	0		;31  - basic
		dw	0		;32
		dw	0		;33  - play
		dw	0		;34  - draw
		dw	int_35
		dw	int_36
		dw	int_37

mbrsec		db	0,0,0,0		; sector 0
		dw	$0100

;contbl					; параметри за клавитурата
;		db	$13		;pause
;		db	$3		;break
;		db	6,7		;cursor replace
;		db	0,7		;cursor insert
;		db	$20,7		;cursor write

;---------------------------------------

		db	10
		db	'ZERO/pdaXrom',10,0

		list	on
		ds	$FFD7 - *, $FF
		checksum

title		db	7,30,48,32
name		db	$8F,$BA,$AB,$A4,$A8,$AD,$20,$36,$30,$31,$5A,0	; "Пълдин 601Z"

		error	*-serial_no
		dw	%1011010001100001	;90-03-01
		dw	$0000			;serial no

		error	*-bios_date
		dw	%1011010001100001	;90-03-01

		error	*-bios_version
		db	2,50			;version 2.50

		error	*-rtswix
		stx	swix		; експортиране на резултати

		error	*-rtswib
		stab	swib		; от интеръпт драйвери

		error	*-rtswia
		staa	swia

		error	*-sysrts
		rts			; sysrts

		error	*-hard_version
		db	$00		; Пълдин 601

		dw	irqhndl
		dw	swihndl
		dw	nmihndl
		dw	reshndl
		error	*
		end
;---------------------------------------
