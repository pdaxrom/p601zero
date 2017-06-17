#asm
    org		$100
    jmp		QZMAIN
    include	../DEVEL/CLIB.INC
    include	../DEVEL/LIBROM.INC
#endasm

#include ../DEVEL/DEVMAP.H

char *ptr_inp;
char *ptr_hex;
int i;
char inp;

main()
{
    ptr_inp = INPUT_SWKEYS;
    ptr_hex = LED_HEX;

    while (1) {
	inp = *ptr_inp;

	if (inp & 1) {
	    puts("button 1 pressed\n\r");
	    *ptr_hex = 1;
	}
	if (inp & 2) {
	    puts("button 2 pressed\n\r");
	    *ptr_hex = 2;
	}
	if (inp & 4) {
	    puts("button 3 pressed\n\r");
	    *ptr_hex = 3;
	}
    }

    return 0;
}
