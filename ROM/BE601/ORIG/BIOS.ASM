; ***********************************************************
; *							    *
; *	      ОПЕРАЦИОННА СИСТЕМА    U n i D O S	    *
; *	    за пе░▒онален мик░окомп╛▓║░ ПЪЛДИН 601 A	    *
; *							    *
; *    Copyright (C) 1988  НИПЛ "П░ог░амно о▒иг│░┐ване"     *
; *							    *
; *		 (C) 1988  Иво Найденов НЕНОВ		    *
; *		 (C) 1988  О░лин Дими▓░ов ШОПОВ 	    *
; *							    *
; ***********************************************************
; *							    *
; *		  Basic Input/Output System		    *
; *		  Version 2.50 / 01-Mar-1990		    *
; *							    *
; ***********************************************************
		list	off

; ПРЕДУПРЕЖДЕНИЕ:
; Тек▒▓а на опе░а╢ионна▓а ▒и▒▓ема ▒е дава ▒амо за ▒п░авка.
; В▒┐ко ди░ек▓но об░║╣ение к║м кода или моди┤и╢и░ане на
; п░оменливи▓е на опе░а╢ионна▓а ▒и▒▓ема на░│╕ава кон╢еп╢и┐▓а
; за ▒║вме▒▓имо▒▓ ▒ ░азли╖ни ве░▒ии. НИПЛ "П░ог░амно о▒иг│░┐ване"
; ▒и запазва п░аво▓о да п░ави п░омени в кода и п░оменливи▓е на
; опе░а╢ионна▓а ▒и▒▓ема ▒ ╢ел подоб░ение на ┤│нк╢иони░ане▓о.
; Не ▒е поема никаква о▓гово░но▒▓ за не▒║вме▒▓имо▒▓ на п░ог░амни
; п░од│к▓и, не▒пазили п░о▓окола за използване на опе░а╢ионна▓а
; ▒и▒▓ема ▒ б║де╣и ве░▒ии.
; Об░║╣ени┐▓а к║м опе░а╢ионна▓а ▒и▒▓ема ▒ледва да ▒е изв║░╕ва▓
; по п░о▓окола опи▒ан в ░║ковод▒▓во▓о за по▓░еби▓ел┐.

;-----------------------------------------------------------

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

		org	$F000
		int	$30		;call monitor
		rts
		jmp	putc

;-----------------------------------------------------------

reshndl 	proc			; д░айве░ за об░або▓ка на RESET
		sei			; заб░ан┐ване на п░ек║▒вани┐▓а

		ldx	#0		; ини╢иализа╢и┐ на PIA
		stx	piacra
		ldx	#$007f
		stx	piadra
		ldx	#$3737
		stx	piacra
		ldaa	#1
		staa	piadrb

		clrb			; ими╢иализа╢и┐ на CRT
		ldx	#videotbl
crtloop 	ldaa	x
		stab	crtaddr
		staa	crtdata
		inx
		incb
		cmpb	#16
		bne	crtloop

		ldx	#swipag 	; н│ли░ане на ▓абли╢а▓а ▒ ад░е▒и▓е
reshndl1	clr	0,x		; на ин▓е░║п▓и▓е и ▒▓░ани╢и▓е им
		inx
		cpx	#swipag+$280
		bne	reshndl1
		ldab	#$70		;│▒▓анов┐ване на ин▓е░║п▓и 00-37
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
ramtest3	clr	0,x		; н│ли░ане на опе░а▓ивна▓а паме▓
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
		clr	rompage 	; изкл╛╖ване на ▒▓░ани╖ни┐ ROM
		clr	indos		; из╖и▒▓ване на ┤лага
		clr	equipment	; из╖и▒▓ване на ┤лага
		clr	configuration	; ┤лагове за ┤лопи▓а▓а

		clr	fdcslct
		inc	fdcslct

		ldx	#contbl
		stx	conparms
		ldx	cur_replace,x
		stx	cursor_start
		clr	insert_mode
		clr	macroflg	; мак░о клави▓│░а
		ldx	#0
		stx	macro_def_ptr

		ldx	#fddtbl
		stx	fddparms

		ldx	#kbd_buffer
		stx	kbd_store
		stx	kbd_load
		ldaa	#$60
		staa	cursor_blink

		ldx	#rstbl
		stx	rsparms

		ldx	#upperram
		txs

		clra			; ини╢иализа╢и┐ на видео ░ежима
		clrb
		int	$12

		ldx	#title		; име▓о на комп╛▓║░а
		int	$23

		ldab	#8		; п░ове░ка на ▒▓░ани╖ни▓е ROM
romloop 	stab	rompage
		ldx	#$a55a		; за 2764 и 27128 п║░ва ╖а▒▓
		bitb	#%00000100
		beq	romt0
		ldx	#$5aa5		; за 27128 в▓о░а ╖а▒▓
romt0		cpx	romstart
		bne	nextrom

		ldx	#romstart	; кон▓░олна ▒│ма на ROM
		clra
romloop1	adda	0,x
		inx
		cpx	#romstart+$2000
		bne	romloop1
		tsta
		bne	nextrom
		pshb

		ldx	#romstart+$10	; зака╖ане на ин▓е░║п▓ д░айве░и▓е
romtl		stx	x1		; о▓ ▒▓░ани╖ни▓е ROM
		ldaa	0,x
		beq	romte
		ldab	rompage
		ldx	1,x
		int	$2f
		ldx	x1
		inx
		inx
		inx
		bra	romtl
romte
		jsr	romstart+$a	; ини╢иализа╢и┐ на ▒▓░ани╖ни▓е ROM
		pulb
nextrom 	incb
		cmpb	#$10
		bcs	romloop 	;<
		clr	rompage

		ldx	#$F000
		clra
mainrom 	adda	x
		inx
		bne	mainrom
		tsta
		beq	mainrom_ok
		int	$00
mainrom_ok

		ldab	#2		; init printer port
		int	$26

		ldab	#4
		ldaa	#%100110
		int	$27

		cli
		ldaa	fdcstat
		anda	#%11000000
		cmpa	#%10000000
		bne	nofloppy	;no floppy

		ldaa	#$80		; initialize
		int	$17		; reset FDC

		ldx	#bootparm	; ини╢иализа╢и┐ на ┤лопи-кон▓░оле░а
		ldaa	#1		; ╖е▓ене на ╢илинд║░ 0, глава 0,
		int	$17		; ▒ек▓о░ 1
		tsta
		bne	nofloppy
		ldx	$2fe		; п░ове░ка за п░инадлежно▒▓
		cpx	#$a55a
		bne	nofloppy
		jsr	$150
nofloppy
resetloop	int	$01		; к░ай по RESET век▓о░а
		bra	resetloop

		endp
;---------------------------------------
inthandlers	proc
		global	nmihndl, irqhndl

nmihndl 				; д░айв░ за NMI п░ек║▒ване
		ldab	swipag+1	;int02
		lsrb
		lsrb
		lsrb
		lsrb
		ldx	swivec+4	;int02
		bra	irqhndl1
;---------------
irqhndl
		ldab	swipag+4	;int09
		ldx	swivec+18	;int09
		tst	piacra		;клави▓│░а▓а ли е ?
		bmi	irqhndl1	;да
		ldab	swipag+1	;int03
		ldx	swivec+6	;int03
		tst	piacrb		; д░айве░ за IRQ п░ек║▒ване и
		bpl	irqhndl1	; 50 Hz
		tst	piadrb
		ldab	swipag+2	;int05
		ldx	swivec+10	;int05
irqhndl1	ldaa	rompage 	; об╣а ╖а▒▓ на NMI и IRQ д░айве░и▓е
		psha
		andb	#$0f
		beq	irqhndl2
		stab	rompage
irqhndl2	cpx	#0
		beq	irqhndl3
		jsr	0,x
irqhndl3	pula
		staa	rompage
		rti
		endp

;---------------------------------------
swihndl 	proc			; д░айве░ за об░або▓ка на SWI
		sei			; о▒иг│░┐ва п▒евдо-ин▒▓░│к╢и┐▓а INT
		inc	indos		; ниво на вложено▒▓
		tsx
		lds	5,x		; компен▒и░ане на PC за номе░а на
		des			; ин▓е░║п▓а
		pula			; номе░ на ин▓е░║п▓а
		ins
		sts	5,x
		txs
		psha
		bsr	exchregs	; ░азм┐на на SWI п░оменливи▓е и ▒▓ека
		pula			; номе░ на ин▓е░║п▓а
		ldab	rompage 	; ▓ек│╣а ROM ▒▓░ани╢а
		pshb			; ▒па▒┐ва ▒е в ▒▓ека

		tab			; извли╖ане на ▒▓░ани╢а▓а на ин▓е░║п▓а
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
		stab	rompage
swihndl4
		ldab	#$77		;$ee/2
		asla			; извли╖ане на ад░е▒а на ин▓е░║п▓а
		rolb
		staa	swihndl_x+1
		stab	swihndl_x
		ldx	swihndl_x
		ldaa	swivec+1,x
		ldab	swivec,x
		beq	swihndl2
		bsr	swihndl3	; изп║лнение на ин▓е░║п▓а
swihndl2
		sei			; в║▒▓анов┐ване ▒лед ин▓е░║п▓а
		pulb
		stab	rompage 	; п░еди╕на▓а ▒▓░ани╢а
		tsx
		bsr	exchregs	; ░азм┐на на ░еги▒▓░и▓е и ▒▓ека
		dec	indos		; ниво на вложено▒▓
		rti

exchregs
		ldaa	1,x
		ldab	swib		; ░еги▒▓║░ B
		staa	swib
		stab	1,x

		ldaa	2,x
		ldab	swia		; ░еги▒▓║░ A
		staa	swia
		stab	2,x

		ldaa	3,x
		ldab	swix		; ░еги▒▓║░ X
		staa	swix
		stab	3,x

		ldaa	4,x
		ldab	swix+1
		staa	swix+1
		stab	4,x

		ldaa	0,x		; ░еги▒▓║░ P
		ldab	swic
		staa	swic
		stab	0,x
		rts

swihndl3
		psha			; за░еждане на ░еги▒▓░и▓е и
		pshb			; изп║лнение
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
reset		proc
loop0		ldaa	piacra
		eora	#8
		staa	piacra
loop1		dex
		bne	loop1
		bra	loop0
		endp

;--------------------------------------
; TIME SUPPORT
;--------------------------------------
timer		proc
		ldx	#0
		cpx	synchro_addr
		beq	timer0
		ldab	#12
		ldaa	synchro_addr
		jsr	set6845
		incb
		ldaa	synchro_addr+1
		jsr	set6845
		stx	synchro_addr

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
		ldaa	#$FF
		int	$17

		tst	key_timer0
		beq	exit0
		dec	key_timer0
exit0
		tst	key_timer1
		beq	exit1
		dec	key_timer1
exit1
		tst	key_timer2
		beq	exit2
		dec	key_timer2
		bne	exit2
		ldaa	#$FF
		staa	old_key
exit2		rts

		endp

;---------------------------------------
; KEYBOARD
;---------------------------------------
int09		proc

		tst	key_timer0	;▓в║░де б║░зо - игно░и░аме
		beq	ok
		ldaa	piadra
return		rts
ok
		clrb
loop		ldaa	piadra
		decb
		beq	return
		cmpa	#$ff
		beq	loop		; ignore false reading
;
		ldab	#30
		cmpa	old_key
		bne	differ

		tst	key_timer1
		bne	ret		; ▒║╣о▓о коп╖е много ▒ко░о

		ldab	#3
differ		stab	key_timer1
		staa	old_key

		ldx	kbd_store
		cmpa	#_BREAK
		beq	clear
		cmpa	#_PAUSE
		bne	no_clear
clear		stx	kbd_load
no_clear
		inx
		cpx	#kbd_buffer_end
		bne	s1
		ldx	#kbd_buffer
s1		stx	kbd_temp	; new kbd_store
		cpx	kbd_load	; buffer full ?
		beq	ret		; yes

		ldab	piacra
		bitb	#8		; п░ове░ка и об░або▓ка на CAPSLOCK
		beq	no_toggle
		cmpa	#$c0
		bcc	no_toggle
		cmpa	#$41
		bcs	no_toggle
		cmpa	#$5a
		bls	toggle
		cmpa	#$61
		bcs	no_toggle
		cmpa	#$7a
		bls	toggle
		cmpa	#$80
		bcs	no_toggle
toggle		eora	#$20
no_toggle
		cmpa	#_CAPS_LOCK
		bne	not_caps_lock
		eorb	#8		; ▓░иге░и░ане на ▒ве▓одиода
		stab	piacra
		bra	no_store
not_caps_lock
		cmpa	#_CYRILLIC	; п░ове░ка и об░або▓ка на КИР/LAT
		bne	not_cyrillic
		ldaa	piadrb
		eora	#1		; ▒м┐на на клави▓│░а▓а
		staa	piadrb
		ldab	#$60
		lsra
		bcs	lat
		clrb
lat		stab	cursor_blink
		bra	no_store
not_cyrillic
		ldx	kbd_store	; store char
		staa	x
		ldx	kbd_temp
		stx	kbd_store
no_store
		bsr	soundkey
ret
		ldab	#3
		stab	key_timer0
		ldab	#5
		stab	key_timer2
		rts


soundkey	ldaa	#15
soundkey0	ldab	piacrb
		eorb	#8
		stab	piacrb
		ldab	key_timer1
soundkey1	decb
		nop
		bne	soundkey1
		ldab	piacrb
		eorb	#8
		stab	piacrb
		ldab	key_timer1
soundkey2	incb
		cmpb	#60
		bne	soundkey2
		deca
		bne	soundkey0
		rts
		endp

;---------------------------------------

int10		proc			; ▓е▒▓ на клави▓│░а▓а
		sei
		ldaa	#$FF
		ldx	kbd_load
		cpx	kbd_store
		beq	return
		ldaa	x
return		staa	swia
		rts
		endp

;---------------------------------------
int11		proc
		bra	entry
loop		cmpa	cursor_blink
		beq	same

entry		ldaa	cursor_blink
		psha
lat		oraa	cursor_start
		ldab	#10
		bsr	set
		incb
		ldaa	cursor_end
		bsr	set
		pula
same
		cli
		nop
		sei
		ldx	kbd_load
		cpx	kbd_store
		beq	loop

		ldaa	x
		inx
		cpx	#kbd_buffer_end
		bne	skip
		ldx	#kbd_buffer
skip		stx	kbd_load
		staa	swia

		ldx	conparms
		ldab	#10
		ldaa	cur_notread,x
		bsr	set
		incb
		ldaa	cur_notread+1,x
set		jmp	set6845

		endp

;---------------------------------------
; INIT VIDEO MODE
;---------------------------------------
;  A - mode: 0 - text40, B = 0 - b/w, B <> 0 - attr
;	     1 - graf16
;	     2 - graf4, B - palette
;	     3 - graf2
;	     4 - text40, B = 0
;
int12		proc			; ини╢иализа╢и┐ на видео░ежима
		global	set6845
initscr 	sei
		anda	#$7f
		cmpa	#5
		bcs	modeok
		rts

modeok		anda	#3		;force 4 --> 0
		clr	queuelen
		stx	scrbase
		stx	scraddr
		staa	scrmode
		staa	tmpx+1

		cmpa	#2		;grmidres
		bne	initscr1
		stab	palette
		andb	#3
		aslb
		aslb
		aslb
		bra	initscr3

initscr1	tsta			; text40 ?
		bne	initscr2	; no
		tstb			; b/w ?
		beq	initscr2
		stab	attribute
	    ;	ldab	#4
	    ;	db	$C1		; CMPB #
initscr2	clrb

initscr3	ldaa	#/piatbl
		staa	tmpx
		ldx	tmpx
		orab	piatbl,x
		ldaa	piadrb
		anda	#$C1
		staa	piadrb
		orab	piadrb
		stab	piadrb

		ldx	#videotbl
		ldaa	6,x		; rows
		ldab	scrmode
		andb	#3
		bne	grafmode
textmode
		staa	scrrows 	; б░ой ░едове
		inca
		inca
		bsr	setrows
		ldaa	1,x
		staa	scrcols 	; б░ой ▒имволи на ░ед
		inca
		inca
		bsr	setcols
		ldx	16,x
		stx	scrsize

		ldab	#/screen
		stab	scrbase 	; на╖ален ад░е▒ на ек░ана
		ldaa	#screen
		staa	scrbase+1
		tst	swia
		bpl	textmode1
		ldab	scraddr
		ldaa	scraddr+1
textmode1	stab	scraddr
		staa	scraddr+1
		bra	setmode1
grafmode
		bsr	setrows
		ldaa	1,x
		bsr	setcols
		ldab	scrbase
		ldaa	scrbase+1
		lsrb
		rora
		lsrb
		rora
		lsrb
		rora
setmode1	pshb
		ldab	#13
		bsr	set6845
		decb
		pula
		bsr	set6845
		tst	swia
		bmi	return

		ldx	#system_line	;clear system line
		ldab	#80
loop		clr	x
		inx
		decb
		bne	loop

		ldaa	#12		;cls
		int	$22
return		rts

setcols 	ldab	#1
		db	$8C		;cpx # - skip2
setrows 	ldab	#6
set6845 	stab	crtaddr 	; ини╢иализа╢и┐ на СМ607
		staa	crtdata
		rts

		endp

;---------------------------------------
; GET VIDEO MODE
;---------------------------------------
int13		proc			; п░о╢ед│░а▓а ек▒по░▓и░а:
		sei
		ldx	scrbase 	; базов ад░е▒ на ек░ана
		ldab	palette
		ldaa	scrmode
		bita	#3
		bne	j1
		ldab	attribute
j1		jmp	rtswix
		endp

;---------------------------------------
; GET CURSOR POSITION
;---------------------------------------
int14		proc			; п░о╢ед│░а▓а ек▒по░▓и░а:
		sei
		ldx	scraddr 	; ад░е▒ на ек░ана,
		ldaa	ch		; ╡о░изон▓ална пози╢и┐ на к│░▒о░а
	;	ldab	scrmode
	;	bne	j1
	;	lsra			; only for text 40
j1		ldab	cv		; ве░▓икална пози╢и┐ и
		jmp	rtswix
		endp

;---------------------------------------
; SET CURSOR POSITION
;---------------------------------------
int15		proc			; п░о╢ед│░а▓а ек▒по░▓и░а:
		sei
		cmpb	scrrows
		bcc	sorry
		stab	cv
	 ;	ldab	scrmode
	 ;	bne	j1
	 ;	asla			;only for mode 40
j1		cmpa	scrcols
		bcc	sorry
		staa	ch
sorry		jmp	fixcur
		endp

;---------------------------------------
; SET ATTRIBUTE
;---------------------------------------
int16		proc
		sei
		stab	attribute
		rts
		endp

;---------------------------------------
; FLOPPY LOW LEVEL SUPPORT
;---------------------------------------
int17		proc
		sei
		clr	retcode
		cmpa	#$FF
		beq	MOTOR_PER
		cmpa	#$80
		beq	INIT
		tsta
		bne	cmd
		jmp	RESET
cmd
		ldab	_drive,x
		comb			;swap drives A and B
		andb	#1
		stab	drive
		ldab	_track,x
		stab	track
		ldab	_head,x
		andb	#1
		stab	head
		aslb
		aslb
		orab	drive
		stab	headdrive
		ldab	_sector,x
		stab	sector
		ldx	_buffer,x
		stx	buffer

		staa	double_step
		anda	#$7F
		ldab	#'R'
		ldx	#READ
		deca
		beq	call
		ldab	#'W'
		ldx	#WRITE
		deca
		beq	call
		ldab	#'S'
		ldx	#SEEK_CMD
		deca
		beq	call
		ldab	#'F'
		ldx	#FORMAT
		deca
		beq	call
		rts

;---------------
MOTOR_PER
		tst	mcounter
		beq	motor_perz
		dec	mcounter
		bne	motor_perz
		ldaa	fdcslct
		anda	#7
		staa	fdcslct
motor_perz	rts

;---------------
INIT
		clr	mcounter
		ldaa	#$FF
		staa	olddrive
		bra	RESET

;---------------
call
		stx	tmpx
		ldx	system_scrbase
		stab	81,x		;42+39
		ldx	tmpx
		ldab	mcounter	;вл╛╖ване на мо▓о░а
		clr	mcounter
		ldaa	#1		;motor on
		asla
		oraa	drive		;DS
		asla			;tc
		sec			;-reset
		rola
		staa	fdcslct

		oraa	#2
		staa	tc
		ldaa	drive
		cmpa	olddrive
		bne	motoron1
		tstb
		bne	motoron2
motoron1	ldab	#$100
motoron1lp	deca
		bne	motoron1lp
		decb
		bne	motoron1lp
motoron2
		jsr	x		;execute command
		ldx	system_scrbase
		clr	81,x		;42+39
motoroff
		ldaa	drive
		staa	olddrive
		ldx	fddparms
		ldaa	_motor_delay,x
		staa	mcounter
		tst	retcode
		beq	done
RESET		bsr	reset0

done		ldaa	retcode
		staa	swia
correct_time	ldaa	$18		;hun
		adda	#10		;.10 sec
		staa	$18
		rts

;---------------
reset0		clr	fdcslct
		ldaa	#1
		staa	fdcslct
		ldaa	#$FF
		staa	recalib_flg

		ldaa	#3		;specify
		staa	transfer_buff
		ldx	fddparms
		ldx	_head_time,x
		stx	transfer_buff+1
		ldab	#3
		jsr	command 	;no return if error
rts0		rts

;---------------
SEEK_CMD
		bsr	seek
		tst	retcode
		bne	seek_ret
		jsr	read_id
		ldab	transfer_buff+3
		stab	swib
seek_ret	rts

seek
		clrb
		ldaa	drive
		sec
seek0		rolb
		deca
		bpl	seek0		;note that carry is clear !
		bitb	recalib_flg
		beq	seek1		;no recalibration needed
		eorb	recalib_flg	;clear flag
		stab	recalib_flg

		ldaa	#7		;recalibrate command
		staa	transfer_buff
		ldaa	drive
		staa	transfer_buff+1
		ldab	#2
		jsr	command 	;no return if error !
		ldaa	#80		;80 cylinders difference
		bsr	seek2
seek1
		ldaa	#$F		;seek command
		staa	transfer_buff
		ldaa	headdrive
		staa	transfer_buff+1
		ldaa	track
		tst	double_step	;if command had bit 7 on (R,W,S,F)
		bpl	single
		asla
single		staa	transfer_buff+2
		ldab	#3
		jsr	command 	;no return if error !

		ldab	track
		ldaa	track_A
		tst	drive
		beq	seek1a
		ldaa	track_B
seek1a		tst	double_step
		bpl	seek1b
		aslb
seek1b		sba
		bpl	seek2
		nega
seek2
		inca
		ldx	fddparms
		ldab	_head_time,x
		comb
		lsrb
		lsrb
		lsrb
		lsrb
		incb
		stab	counter
seek2a		ldx	counter
seek2b		nop
		dex
		bne	seek2b
		deca
		bne	seek2a

seek3
		ldaa	#8		;sense int status command
		staa	transfer_buff
		ldab	#1
		jsr	command 	;no return if error !
		ldab	#2
		jsr	result
		tst	retcode
		bne	seek4
		ldaa	transfer_buff+1
		tst	drive
		bne	seek3a
		staa	track_A
		bra	seek3b
seek3a		staa	track_B
seek3b
		ldaa	transfer_buff
		anda	#$60
		cmpa	#$60
		bne	seek4
		ldaa	#BAD_SEEK
error		oraa	retcode
		staa	retcode
		ldaa	tc
		staa	fdcslct
seek4		rts

;---------------
READ
		jsr	seek
		tst	retcode
		beq	read_
read9		rts
read_
		ldaa	#$66		;read command
		jsr	rw_cmd		; no return if error

		ldx	buffer

read0		ldaa	fdcstat
		bmi	read1a
		clr	counter
read0a		ldaa	fdcstat
		bmi	read1a
		inc	counter+1
		bne	read0a
		inc	counter
		bne	read0a
read0b		anda	#%00100000
		beq	read3
		ldaa	#TIMEOUT
		jsr	error
		bra	read3

read1		ldaa	fdcstat
		bmi	read1a
		ldaa	fdcstat
		bpl	read0b
read1a		ldaa	fdcdata
		staa	x
		inx
		decb
		bne	read1

read2		ldaa	fdcstat
		bmi	read2a
		ldaa	fdcstat
		bpl	read0b
read2a		ldaa	fdcdata
		staa	x
		inx
		decb
		bne	read2
read3
		ldaa	tc
		staa	fdcslct
read_result	ldab	#7
		jsr	result
		jmp	rw_res

;---------------

read_id 	ldaa	#$4A		;read id
		staa	transfer_buff
		ldaa	headdrive
		staa	transfer_buff+1
		ldab	#2
		jsr	command 	;no return if error
		bra	read_result

;---------------
WRITE
		ldaa	#retry_cnt
		staa	retry
write_
		dec	retry
		bpl	write_ok
write9		rts

write_ok
		jsr	correct_time
		clr	retcode

		jsr	chk_wr_prot
;		tst	retcode
;		bne	write9
		jsr	seek
		tst	retcode
		bne	write9
		bsr	read_id
		tst	retcode
		bne	write9

		ldaa	#$45		;write command
		jsr	rw_cmd		;no return if error

		ldx	buffer

write0		ldaa	fdcstat
		bmi	write1a
		clr	counter 	;6
write0a 	ldaa	fdcstat 	;4
		bmi	write1a 	;4
		inc	counter+1	;6
		bne	write0a 	;4
		inc	counter 	;6
		bne	write0a 	;4
write0b 	anda	#%00100000
		beq	write3
		ldaa	#TIMEOUT
		jsr	error
		bra	write3

write1		ldaa	fdcstat 	;4
		bmi	write1a 	;4
		ldaa	fdcstat
		bmi	write1a
;		ldaa	fdcstat
;		bmi	write1a
		ldaa	fdcstat
		bpl	write0b
write1a 	ldaa	x		;5
		staa	fdcdata 	;5
		inx			;4
		decb			;2
		bne	write1		;4

write2		ldaa	fdcstat
		bmi	write2a
		ldaa	fdcstat
		bmi	write2a
;		ldaa	fdcstat
;		bmi	write2a
		ldaa	fdcstat
		bpl	write0b
write2a 	ldaa	x
		staa	fdcdata
		inx
		decb
		bne	write2
write3
		ldaa	tc
		staa	fdcslct
		ldab	#7
		jsr	result
		jsr	rw_res
		ldaa	retcode
		cmpa	#$40		;timeout
		beq	write3a
		cmpa	#$02		;overrun
		beq	write3a
		rts
write3a 	jmp	write_

;---------------
format
		ldaa	#retry_cnt
		staa	retry

format_
		dec	retry
		bpl	format_ok
format9 	rts

format_ok
		jsr	correct_time
		clr	retcode

		jsr	chk_wr_prot
;		tst	retcode
;		bne	format9
		jsr	seek
		tst	retcode
		bne	format9

		ldaa	#$4D		;format command
		staa	transfer_buff
		ldaa	headdrive
		staa	transfer_buff+1
		ldx	fddparms
		ldaa	_sector_type,x
		staa	transfer_buff+2
		ldaa	_sectors_per,x
		staa	transfer_buff+3
		ldaa	_gap2,x
		staa	transfer_buff+4
		ldaa	_fill_byte,x
		staa	transfer_buff+5
		ldab	#6
		jsr	command 	; no return if error (goes to format8)

		ldx	buffer
		ldab	sector
		aslb
		aslb

format0 	ldaa	fdcstat
		bmi	format1a
		ldaa	fdcstat
		bmi	format1a
		clr	counter
format0a	ldaa	fdcstat
		bmi	format1a
		inc	counter+1
		bne	format0a
		inc	counter
		bne	format0a
format0b	anda	#%00100000
		beq	format3
		ldaa	#TIMEOUT
		jsr	error
		bra	format3

format1a	ldaa	x
		staa	fdcdata
		inx
		decb
		bne	format0
format3
		ldaa	tc
		staa	fdcslct
		ldab	#7
		jsr	result
		jsr	rw_res
		ldaa	retcode
		cmpa	#$40		;timeout
		beq	format3a
		cmpa	#$02		;overrun
		beq	format3a
		rts
format3a	jmp	format_

;---------------
chk_wr_prot	ldaa	#4
		staa	transfer_buff
		ldaa	headdrive
		staa	transfer_buff+1
		ldab	#2
		jsr	command 	;no return if error !
		ldab	#1
		jsr	result
		ldaa	transfer_buff
		anda	#$40
		bne	chk_wr_prot1
chk_wr_prot0	rts
chk_wr_prot1	ldaa	#WR_PROT
		jmp	error

;---------------
rw_cmd
		staa	transfer_buff
		ldaa	headdrive
		staa	transfer_buff+1
		ldaa	track
		staa	transfer_buff+2
		ldaa	head
		staa	transfer_buff+3
		ldaa	sector
		staa	transfer_buff+4
		ldx	fddparms
		ldaa	_sector_type,x
		staa	transfer_buff+5
		ldaa	_sectors_per,x
		staa	transfer_buff+6
		ldaa	_gap1,x
		staa	transfer_buff+7
		ldaa	_DTL,x
		staa	transfer_buff+8
		ldab	#9

command 	ldx	#transfer_buff
command0	clr	counter
command00	ldaa	fdcstat
		anda	#$C0
		cmpa	#$80
		beq	command1
		dec	counter
		bne	command00
		ins			;! return to previous level if error
		ins
		ldaa	#TIMEOUT
		jmp	error

command1	ldaa	x
		staa	fdcdata
		inx
		decb
		bne	command0
		rts			;! note that B = 0

;---------------
result
		ldx	#transfer_buff	;3
result0 	ldaa	fdcstat 	;4
		anda	#$C0		;2
		cmpa	#$C0		;2
		beq	result1 	;4
		clr	counter
result0a	ldaa	fdcstat
		anda	#$C0
		cmpa	#$C0
		beq	result1
		dec	counter+1
		bne	result0a
		dec	counter
		bne	result0a
		ldaa	#TIMEOUT
		jmp	error

result1 	ldaa	fdcdata 	;4
		staa	x		;6
		inx			;4
		decb			;2
		bne	result0 	;4

		ldaa	tc
		eora	#2		;clear tc
		staa	fdcslct
		rts

;---------------
rw_res
		tst	retcode
		bne	rw_return	;old error
		ldaa	transfer_buff	;ST0
		anda	#$C0
		beq	rw_return	;ok

		ldab	#BAD_NEC
		cmpa	#$40
		bne	rw_fail

		ldaa	transfer_buff+1
		ldab	#NO_REC
		asla
		bsr	rw_fail

		ldab	#BAD_CRC
		asla
		asla
		bsr	rw_fail

		ldab	#OVERRUN
		asla
		bsr	rw_fail

		ldab	#NO_REC
		asla
		asla
		bsr	rw_fail

		ldab	#WR_PROT
		asla
		bsr	rw_fail

		ldab	#BAD_ADDR
		asla

rw_fail 	bcc	rw_return
		orab	retcode
		stab	retcode
rw_return	rts

		endp

;---------------------------------------
; SERIAL SUPPORT
;---------------------------------------
rs232c		proc			; или ▒е░ийни┐ в╡од
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

recbit		pshb
		bsr	wayt
		ldab	piadrb
		aslb
		bcc	rcb1
		com	allcap
rcb1		pulb
		rts

rsin		bsr	ways
		ldab	bauds,x
		lsrb
		bsr	wa1
		ldab	bits,x
rsi1		bsr	recbit
		rora
		decb
		bne	rsi1
		bsr	recbit		;parity
wayt		ldab	bauds,x
		db	$8C
wait1		ldab	#20
wa1		decb
		bne	wa1
		ldab	allcap
		rts
ways		ldx	rsparms
		ldab	piadrb
		bmi	ways
		ldab	parity,x
		stab	allcap
		rts

int18		sei
		inc	hundreds
		bsr	rsin
		sec
		bne	return
		clc
return		staa	swia
		tpa
		staa	swic
		rts

int19		sei
		inc	hundreds
rsout		bsr	ways
		clc
		bsr	trbit		;start bit
		ldab	bits,x
rso1		lsra
		bsr	trbit
		decb
		bne	rso1
		comb
		addb	allcap
		bsr	trbit		;parity bit
trstop		sec
trbit		pshb			;stop bit,bit
		ldab	piadrb
		andb	#$BF
		bcc	trb1
		orab	#$40
		com	allcap
trb1		stab	piadrb
		bsr	wayt
		pulb
		rts
		endp

;---------------------------------------
; GETCHAR
;---------------------------------------
; procedure reads keyboard and expands keys

int20		proc

again		tst	macroflg
		bne	inmacro
get_key 	int	$11		;get key
		cmpa	#_BREAK
		beq	break
		ldx	conparms
		cmpa	key_break,x
		bne	search
break		int	$04
		bra	get_key

search		ldx	macro_def_ptr
		beq	exit
search_loop	ldab	x
		cmpb	#$ff
		beq	exit
		cba
		beq	found
skip_loop	inx
		ldab	x
		bne	skip_loop
		inx
		bra	search_loop
found
		stx	macroptr
inmacro 	ldx	macroptr
		inx
		stx	macroptr
		ldaa	x
		staa	macroflg
		beq	again
exit		jmp	rtswia
		endp


;---------------------------------------
; GetLine (mini version)
;---------------------------------------
; Import: X - buffer pointer, B - max length
; Export: A - length
;
;---------------------------------------
int21		proc
		ldaa	scrcols
		suba	ch
		deca
		cba
		bcc	ok
		tab
ok		stab	maxb
		clrb
again		int	$20
		cmpa	#$c0		;Fkeys not collected
		beq	done
		bhi	again

		cmpa	#_BACKSPACE
		bne	char
		tstb
		beq	again
		dex
		decb
		bra	echo

char
		cmpb	maxb
		bne	store
		ldaa	#7
		bra	echo

store		staa	x
		inx
		incb
		cmpa	#$20		;control keys not echoed
		bcs	again
echo		int	$22
		bra	again

done		clr	x
		stab	swia
		rts
		endp

;---------------------------------------
; WRITE CHAR
;---------------------------------------
putc		psha
		pshb
		tab
		tpa
		psha
		tba
		sei
		stx	putchar_x
		bsr	int22
		ldx	putchar_x
		pula
		tap
		pulb
		pula
		rts

int22		proc			; пи▒ане на ▒имвол на ек░ана
		global	fixcur
		sei
		ldab	scrmode
		andb	#3
		bne	return0 	;graphic modes not supported
		tst	queuelen
		beq	screen0
		ldx	queueptr	; п░ове░ка за опа╕ка
		staa	0,x
		inx
		stx	queueptr
		dec	queuelen
		bne	return1
		ldx	#queuebuf
		ldab	0,x		;command
		cmpb	#$1f		;attribute
		bne	queue1
		ldaa	1,x
		staa	attribute
return0 	rts
queue1		cmpb	#$1b		;esc
		bne	queue2
		ldaa	1,x		; пе╖а▓ на ▒имвола ка▓о но░мален
		bra	normchar
queue2		cmpb	#$1e		;goxy
		bne	return1
		ldaa	1,x
		suba	#$20		; │▒▓анов┐ване на пози╢и┐▓а на к│░▒о░а
	   ;	ldab	scrmode
	   ;	bne	queue20
	   ;	asla			; for mode 40
queue20 	cmpa	scrcols
		bcc	queue21
		staa	ch
queue21 	ldaa	2,x
		suba	#$20
		cmpa	scrrows
		bcc	queue22
		staa	cv
queue22 	bra	fixcur

screen0
		cmpa	#$7f		; п░ове░ка за кон▓░олни ▒имволи
		beq	screen1
		cmpa	#$20
		bcc	normchar
screen1 	jmp	ctrlchar

normchar    ;	psha
	    ;	ldaa	scrmode
	    ;	bne	normchar0
	    ;	ldaa	attribute
	    ;	bsr	normchar1
normchar0   ;	pula
normchar1	ldx	curaddr 	; но░мален ▒имвол
		bsr	putchar
adv		ldaa	ch
		inca
		cmpa	scrcols
;		bcs	adv_ok
;		jmp	lf
		bcc	return1
adv_ok		staa	ch
		ldx	curaddr
		inx
		stx	curaddr
		jmp	putcursor
return1 	rts

putchar 	stx	scrtmpx 	; по▒▓ав┐не на ▒имвола на ек░ана
		pshb
		staa	scrtmp
		staa	0,x
		ldaa	scrtmpx+1
		ldab	scrtmpx
		suba	scrsize+1
		sbcb	scrsize
		cmpb	scrbase
		bne	putchar1
		cmpa	scrbase+1
putchar1	bcs	putchar2
		staa	altaddr+1
		stab	altaddr
		ldx	altaddr
		ldaa	scrtmp
		staa	0,x
putchar2	pulb
		ldx	scrtmpx
		rts

fixcur					; ┤ик▒и░ане на к│░▒о░а
		ldaa	scrcols
		inca
		inca
		staa	scrtmp
		ldaa	cv
		psha
		clrb
		pshb
		ldaa	ch
		clrb
		adda	scraddr+1
		adcb	scraddr
		staa	curaddr+1
		stab	curaddr
fixcur1 	lsr	scrtmp
		bcc	fixcur2
		adda	curaddr+1
		adcb	curaddr
		staa	curaddr+1
		stab	curaddr
fixcur2 	pulb
		pula
		asla
		rolb
		psha
		pshb
		tst	scrtmp
		bne	fixcur1
		ins
		ins
putcursor				; по▒▓ав┐не на к│░▒о░а
		ldx	kbd_load
		cpx	kbd_store
		beq	checkend
		ldaa	x
		ldx	conparms
		cmpa	#_BREAK
		beq	is_break
		cmpa	key_break,x
		bne	check_pause
is_break	int	$11		;remove from buffer
		int	$04
		ldx	conparms
check_pause	cmpa	#_PAUSE
		beq	is_pause
		cmpa	key_pause,x
		bne	checkend
is_pause	int	$11		;remove from buffer
		int	$11
checkend
		ldaa	curaddr+1
		ldab	curaddr
		adda	#2		;fix hardware bug of 2 us delay
		adcb	#0
		psha
		tba
		ldab	#14
		bsr	set_6845
		incb
		pula
set_6845	jmp	set6845 	; ини╢иализа╢и┐ на СМ607

ctrlchar				; кон▓░олен ▒имвол
		cmpa	#$7f
		bne	ctrl1e
del		jsr	bs		; DEL
		ldx	curaddr
		ldaa	#$20
		jmp	putchar

ctrl1e		cmpa	#$1e		; GOTOXY
		bne	ctrl1b
		ldab	#2
		bra	setqueue

ctrl1b		cmpa	#$1F		; attribute
		beq	setqueue1
		cmpa	#$1b		; ESCAPE
		bne	ctrl18
setqueue1	ldab	#1
setqueue	ldx	#queuebuf
		staa	0,x
		inx
		stx	queueptr
		stab	queuelen
		rts

ctrl18		cmpa	#$18		; clear to end of line
		bne	ctrl0d
cleol		ldx	curaddr 	; из╖и▒▓ване до к░а┐ на ░еда
		ldab	ch
cleol1		cmpb	scrcols
		bcc	cleol2
	  ;	ldaa	scrmode
	  ;	bne	cleol3
	  ;	ldaa	attribute
	  ;	jsr	putchar
	  ;	inx
	  ;	incb
cleol3		ldaa	#$20
		jsr	putchar
		inx
		incb
		bne	cleol1
cleol2		rts

ctrl0d		cmpa	#$0d		; CARRIAGE RETURN
		bne	ctrl0c
cr		clr	ch
		jmp	fixcur

ctrl0c		cmpa	#$0c
		bne	ctrl0a
cls					; из╖и▒▓ване на ек░ана
		ldx	scrbase
		ldab	scrrows
		aslb
cls1		ldaa	scrcols
		inca
		inca			;fix hardware bug
cls2		clr	0,x	; 1,x for 601a
		inx
		deca
		bne	cls2
		decb
		bne	cls1
		bsr	clear_sysline

home		clr	ch		; к│░▒о░а в го░ни┐ л┐в ║г║л
		clr	cv
		ldx	scraddr
		stx	curaddr
		jmp	putcursor

clear_sysline	ldaa	scraddr+1
		ldab	scraddr
		adda	scrsize+1
		adcb	scrsize
		staa	system_scrbase+1
		stab	system_scrbase
		ldx	system_scrbase
		sei
		sts	tmps
		lds	#system_line-1
		ldab	#40
clear_sysloop	clr	x
		pula
		pula
		staa	42,x
		inx
		decb
		bne	clear_sysloop
		lds	tmps
		rts

ctrl0a		cmpa	#$0a
		bne	ctrl09
lf					; ░ед надол│
		clr	ch		; for lf = cr+lf
		ldaa	cv
		inca
		cmpa	scrrows
		bcc	scroll
		staa	cv
		jmp	fixcur		; for lf = cr+lf

;		ldaa	curaddr+1
;		ldab	curaddr
;		adda	scrcols
;		adcb	#0
;		staa	curaddr+1
;		stab	curaddr
;		jmp	putcursor
scroll					; ▒к░ол наго░е
		ldaa	scrcols
		inca
		inca
		clrb
		adda	scraddr+1
		adcb	scraddr
scroll4 	staa	scraddr+1
		stab	scraddr
		suba	scrsize+1
		sbcb	scrsize
		cmpb	scrbase
		bne	scroll3
		cmpa	scrbase+1
scroll3 	bcc	scroll4

		ldaa	scraddr+1
		ldab	scraddr
		adda	scrsize+1
		adcb	scrsize
		suba	scrcols
		sbcb	#0
		staa	altaddr+1
		stab	altaddr
		ldx	altaddr
		dex
		dex			;fix hardware bug
		clrb
		jsr	cleol1
		jsr	clear_sysline

		ldx	scraddr
		stx	synchro_addr
		jmp	fixcur


ctrl09		cmpa	#$09		; ▓аб│ла╢и┐
		bne	ctrl08
tab		ldaa	ch
		adda	#8
		anda	#%11111000
		cmpa	scrcols
		bcc	tab9
		staa	ch
tab9		jmp	fixcur

ctrl08		cmpa	#$08		; BACKSPACE
		bne	ctrl07
bs		ldaa	ch
		beq	bs9
		dec	ch
		ldx	curaddr
		dex
		stx	curaddr
bs9		jmp	putcursor


ctrl07		cmpa	#$07
		bne	return2
bell					; BELL
		ldx	#200
bell0		ldab	#100
bell1		decb
		bne	bell1
		ldaa	piacrb
		eora	#%00001000
		staa	piacrb
		dex
		bne	bell0
return2 	rts
		endp

;---------------------------------------
; WRITE LINE
;---------------------------------------
int23		proc			; пи▒ане на ░ед
putln		ldaa	0,x
		beq	putln1
		int	$22
		inx
		bra	putln
putln1		rts
		endp


;-----------------------------------------
; PRINT CHAR
;-----------------------------------------
; send char to stdprn
; IMPORT: A - char
;	  B - mode: 0 - print char
;		    1 - get status
;		    2 - init
; EXPORT: A - status/error
;-----------------------------------------
int26		proc

prndra		equ	$E634
prndrb		equ	$E635
prncra		equ	$E636
prncrb		equ	$E637

		tstb
		beq	print_char
		decb
		beq	get_status
		decb
		beq	init
		rts

print_char	ldab	#10
loop		tst	prndra
		bpl	ok
		dex
		bne	loop
		decb
		bne	loop
		ldaa	#1		;timeout
		bra	exit

ok		staa	prndrb
		ldaa	#$34
		staa	prncra
		ldaa	#$3c
		bra	strobe

init		ldx	#0
		stx	prncra
		ldx	#$7ff		;PA2-0, PB - out
		stx	prndra
		ldaa	#$34
		staa	prncrb
		ldaa	#$3c
		staa	prncrb
strobe		staa	prncra
get_status	clra
exit		oraa	prndra
		jmp	rtswia
		endp


;-----------------------------------------
; UNISGNED MULTIPLY
;-----------------------------------------
; BA = A * B
int28		proc
		ldx	#8
		clrb
loop		lsr	swia
		bcc	skip
		addb	swib
skip		rorb
		rora
		dex
		bne	loop
		jmp	rtswib
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
		ldaa	x1+1		;src end - извли╖ане на па░аме▓░и▓е
		ldab	x1		;	   на команда▓а MOVE
		suba	x2+1		;src beg
		sbcb	x2
		adda	x4+1		;dst beg
		adcb	x4
		staa	x3+1		;dst end
		stab	x3

		ldaa	x4		; оп░едел┐не на по▒ока▓а на ме▒▓ене
		cmpa	x2		; на паме▓
		bne	move1
		ldaa	x4+1
		cmpa	x2+1
move1		bls	mvleft
mvright 				; ме▒▓ене над┐▒но
		lds	x3
		ldx	x1
		inx
mvright1	dex
		ldaa	0,x
		psha
		cpx	x2
		bne	mvright1
		bra	mvend
mvleft					; ме▒▓ене нал┐во
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
int2e		proc			; пол│╖аване на ин▓е░║п▓ век▓о░
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
putvec					; задаване на ин▓е░║п▓ век▓о░
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
		tba			;rompage
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

restbl					; ▓абли╢а ▒ на╖ални ▒▓ойно▒▓и на
					; ин▓е░║п▓и▓е
		dw	reset		;00
		dw	reset		;01
		dw	0		;02
		dw	0		;03
		dw	0		;04
		dw	timer		;05
		dw	0		;06
		dw	0		;07
		dw	0		;08
		dw	int09		;09
		dw	0		;0a
		dw	0		;0b
		dw	0		;0c
		dw	upperram	;0d
		dw	lowerram	;0e
		dw	upperram	;0f
		dw	int10
		dw	int11
		dw	int12
		dw	int13
		dw	int14
		dw	int15
		dw	int16		;16
		dw	int17		;17
		dw	int18		;18
		dw	int19		;19
		dw	0		;1A
		dw	0		;1B
		dw	0		;1c
		dw	0		;1d
		dw	0		;1e
		dw	0		;1f
		dw	int20
		dw	int21
		dw	int22
		dw	int23
		dw	0		;24
		dw	0		;25
		dw	int26		;26
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

;---------------
fddtbl					; па░аме▓░и за ┤лопи
		db	$6F
		db	$03
		db	$2		;sector lng
		db	$9		;eot
		db	$2A		;gap1
		db	$FF		;dtl
		db	$50		;gap2
		db	$FF		;fill byte
		db	$80		;motor

bootparm	db	0,0,0,1,1,0	; па░аме▓░и за INT17 за boot

contbl					; па░аме▓░и за клави▓│░а▓а
		db	$13		;pause
		db	$3		;break
		db	6,7		;cursor replace
		db	0,7		;cursor insert
		db	$20,7		;cursor write

videotbl	db	63,40,48,5,38,0,25,31,0,7,$20,7
		dw	$F000,$F000,42*25

piatbl		db	0,$3E,$24,$38,0

rstbl					; па░аме▓░и за ▒е░ийни┐ в╡од/из╡од
		db	$7e		;bauds - 1200
		db	$08		;bits
		db	$80		;no parity + 2 stop

;---------------------------------------

		db	10
		db	'(C) Software RDL 1987-89, Ivo Nenov',10
		db	' & Orlin Shopov - Eagle software',10,0

		list	on
		ds	$FFD7 - *, $FF
		checksum

title		db	7,30,48,32
name		db	'П║лдин 601 ',0

		error	*-serial_no
		dw	%1011010001100001	;90-03-01
		dw	$0000			;serial no

		error	*-bios_date
		dw	%1011010001100001	;90-03-01

		error	*-bios_version
		db	2,50			;version 2.50

		error	*-rtswix
		stx	swix		; ек▒по░▓и░ане на ░ез│л▓а▓и

		error	*-rtswib
		stab	swib		; о▓ ин▓е░║п▓ д░айве░и

		error	*-rtswia
		staa	swia

		error	*-sysrts
		rts			; sysrts

		error	*-hard_version
		db	$00		; П║лдин 601

		dw	irqhndl
		dw	swihndl
		dw	nmihndl
		dw	reshndl
		error	*
		end
;---------------------------------------
