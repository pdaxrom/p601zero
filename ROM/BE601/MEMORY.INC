; ***********************************************************
; *							    *
; *	      ОПЕРАЦИОННА СИСТЕМА    U n i D O S	    *
; *	    за персонален микрокомпютър ПЪЛДИН 601 A	    *
; *							    *
; *    Copyright (C) 1988-89  НИПЛ "Програмно осигуряване"  *
; *							    *
; *		 (C) 1988-89  Иво Найденов Нненов	    *
; *		 (C) 1988-89  Орлин Димитров Шопов	    *
; *		 (C) 1988-89  Георги Петров Петров	    *
; *		 (C) 1988-89  Леонид Давидович Калев	    *
; *							    *
; ***********************************************************
; *							    *
; *		  System constants & variables		    *
; *		       Version 01-JUN-1989		    *
; *							    *
; ***********************************************************

; Разпределение на паметтa:
;
; $0000 ÷ $005F   - BIOS & XBIOS workarea
; $0060 ÷ $007F   - UniDOS workarea
; $0080 ÷ $00FF   - Pascal | Basic workarea
; $0100 ÷ lomem   - reserved by INT35
; lomem ÷ stack   - free memory
; stack ÷ himem   - the stack itself
; himem ÷ resid.  - allocated memory by INT2A
; resid.÷ $BDFF   - resident memory
; $BE00 ÷ $BEFF   - Pascal workarea
; $BF00 ÷ $BF7F   - XBIOS workarea
; $BF80 ÷ $BF9F   - reserved
; $BFA0 ÷ $BFEF   - system line
; $BFF0 ÷ $BFFF   - typeahead keyboard buffer
; $C000 ÷ $DFFF   - page ROM, UniDOS command interpreter
; $E000 ÷ $E5FF   - UniDOS workarea
; $E600 ÷ $E6FF   - I/O area
; $E700 ÷ $EBFF   - UniDOS workarea
; $EC00 ÷ $ECFF   - UniDOS shell workarea
; $ED00 ÷ $ED4F   - system variables
; $ED50 ÷ $ED7F   - BIOS workarea
; $ED80 ÷ $EFFF   - INT vectors
; $F000 ÷ $FFFF   - BIOS | system text screen (write only)

;------------------------------------------------------------

lowerram	equ	$0100
upperram	equ	$BE00
system_line	equ	$BFA0
kbd_buffer	equ	$BFF0
kbd_buffer_end	equ	$C000
romstart	equ	$C000
swipag		equ	$ED80
swivec		equ	$EE00
screen		equ	$F000
computer_name	equ	$FFDC
serial_no	equ	$FFE8
bios_date	equ	$FFEC
bios_version	equ	$FFEE
rtswix		equ	$FFF0
rtswib		equ	$FFF2
rtswia		equ	$FFF4
sysrts		equ	$FFF6
hard_version	equ	$FFF7

;------------------------------------------------------------
; ПРОМЕНЛИВИ:

; Zero page locations:
indos		equ	$00		; флаг показващ нивото на влагане
equipment	equ	$01
; swihndl_x	equ	$02		; used only by swihndl !!!

swic		equ	$04		; променливи използвани от interrupt
swib		equ	$05		; драйверите за предаване на регистрите
swia		equ	$06		; A, B, X и флаговете C и V; достъпни
swix		equ	$07		; за interrupt драйверите само

tmpp		equ	$09
tmpb		equ	$0A
tmpa		equ	$0B
tmpx		equ	$0C
tmps		equ	$0E

a1		equ	$10
a2		equ	$12
a3		equ	$14
a4		equ	$16

hundreds	equ	$18		; системно време и дата
seconds 	equ	$19		;
minutes 	equ	$1A		;
hours		equ	$1B		;
day		equ	$1C		;
month		equ	$1D		;
year		equ	$1E		;

x1		equ	$20
x2		equ	$22
x3		equ	$24
x4		equ	$26

;---------------
; RAM locations:
resmagic	equ	$ED00		; $A55A
configuration	equ	$ED02		; disks available
disk_types	equ	$ED03		; disks 80 tracks

synchro_addr	equ	$ED04
macroflg	equ	$ED06		; Macro keyboard
macroptr	equ	$ED07
key_timer0	equ	$ED09
key_timer1	equ	$ED0A
key_timer2	equ	$ED0B
kbd_store	equ	$ED0C
kbd_load	equ	$ED0E
ch		equ	$ED10
cv		equ	$ED11
scrmode 	equ	$ED12
scrbase 	equ	$ED13
scrsize 	equ	$ED15
scrrows 	equ	$ED17
scrcols 	equ	$ED18
scraddr 	equ	$ED19
palette 	equ	$ED1B
attribute	equ	$ED1C
cursor_start	equ	$ED1D		; Cursor shape
cursor_end	equ	$ED1E
cursor_blink	equ	$ED1F
system_scrbase	equ	$ED20		; ptr to 26-th line of text screen
conparms	equ	$ED22		; console parms ptr
rsparms 	equ	$ED24		; pseudo rs ptr
fddparms	equ	$ED26		; floppy parms ptr
fontbase	equ	$ED28		; 8 font pages
insert_mode	equ	$ED30		;insert_state
old_key 	equ	$ED31		;

;------------------------------------------------------------
; КОНСТАНТИ:

; Скан кодове от клавитурата

_ESCAPE 	=	$1B
_BACKSPACE	=	$7F
_ENTER		=	$C0
_LEFT		=	$C1
_RIGHT		=	$C2
_DOWN		=	$C3
_UP		=	$C4
_HOME		=	$C5
_END		=	$C6
_PAGE_DOWN	=	$C7
_PAGE_UP	=	$C8
_TAB		=	$ED
_S_TAB		=	$EE
_C_BACKSPACE	=	$EF
_C_ENTER	=	$F0
_C_LEFT 	=	$F1
_C_RIGHT	=	$F2
_C_DOWN 	=	$F3
_C_UP		=	$F4
_C_HOME 	=	$F5
_C_END		=	$F6
_C_PAGE_DOWN	=	$F7
_C_PAGE_UP	=	$F8
_DELETE 	=	$F9
_INSERT 	=	$FA
_CYRILLIC	=	$FB
_CAPS_LOCK	=	$FC
_PAUSE		=	$FD
_BREAK		=	$FE

;---------------------------------------
; грешки на флопи-диск контролера:

BAD_NEC 	=	$80
TIMEOUT 	=	$40
BAD_SEEK	=	$20
BAD_ADDR	=	$10
NO_REC		=	$08
BAD_CRC 	=	$04
OVERRUN 	=	$02
WR_PROT 	=	$01

retry_cnt	=	5		; при грешка на флопито

;---------------------------------------
; Структури:

		section 0
_drive		ds	1
_track		ds	1
_head		ds	1
_sector 	ds	1
_buffer 	ds	2
		ends
;---------------
		section 0
_head_time	db	$CF,$03
_sector_type	db	$02
_sectors_per	db	$09
_gap1		db	$2A
_DTL		db	$FF
_gap2		db	$50
_fill_byte	db	$E5
_motor_delay	db	$80
		ends
;---------------
		section 0
bauds		ds	1
bits		ds	1
parity		ds	1
		ends
;---------------
		section 0
key_pause	ds	1
key_break	ds	1
cur_replace	ds	2
cur_insert	ds	2
cur_notread	ds	2
		ends

;---------------------------------------
; Interrupt vectors:

		section $EE00
		ds	2		;00
res_vec 	ds	2		;01
nmi_vec 	ds	2		;02
irq_vec 	ds	2		;03
brk_vec 	ds	2		;04
		ds	2		;05
		ds	2		;06
		ds	2		;07
		ds	2		;08
		ds	2		;09
macro_def_ptr	ds	2		;0a
		ds	2		;0b
		ds	2		;0c
resident	ds	2
lomem		ds	2
himem		ds	2
		ends

;---------------------------------------
