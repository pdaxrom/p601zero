#asm
    org		$100
    jmp		QZMAIN
    include	../DEVEL/CLIB.INC
    include	../DEVEL/LIBROM.INC
#endasm

#define	chkstk	1
#define	NOSUP	1
int address;
int ret;
int locaddr;
int i;
int *temp;
#define	INTSIZE	2
int	fred[30];

printnum(value)      /*outputs integer as a string to COM1*/
int value;
{
        /* right justified, field size 6 characters including sign*/
        char str[7], sign;
        int x;
        for( x = 0; x < 7; x++ )  str[x] = ' ';
        if( value < 0 ) {
                sign = '-';
                value = (-value);
        }
        else sign = '+';
        x = 6;
        do {
                str[x] = (value % 10) + '0';
                value = value / 10;
                x--;
        } while( value > 0 );
        str[x] = sign;
        for( x = 0; x < 7; x++ ) putc( str[x] );
}

test(t, real, testn) int t; int real; char *testn;
{
	puts("Test\n\r");
	if (t != real) {
		puts(testn);
		puts(" failed\n\r");
		puts("Should be: ");
		printnum(real); printnum(10);
		puts(" was: ");
		printnum(t); printnum(10);
		puts("\n\r");
	}
	if (*temp != ret) {
		puts("retst");
	}
	if (locaddr == 0) locaddr = &t;
	else if (locaddr != &t) {
		puts("locst during");
		puts(testn);
	}
}

main(){
	int x;
	puts("Starting test\n\r");
	i = 1;
	address = &x;
	locaddr = 0;
	address = address + INTSIZE;
	temp = address;
	ret = *temp;
	fred[3] = 3;
	test(fred[3], 3, "fred[3] = 3");
/*	test(INTSIZE, sizeof(int), "INTSIZE"); */
/*	test(sizeof(char), 1, "sizeof char"); */
	test(1 + 4, 1,  "(should fail) 1+4");
	test(1022 + 5, 1027, "1022 + 5");
	test(4 + 5, 9, "4 + 5");
	test(1022 * 3, 3066, "1022 * 3");
	test(4 * - 1, -4, "4 * - 1");
	test(4 * 5, 20, "4 * 5");
	test(1000 - 999, 1, "1000 - 999");
	test(1000 - 1200, -200, "1000 - 1200");
	test(-1 - -1, 0, "-1 - -1");
	test(4 >> 2, 1, "4 >> 2");
	test(1234 >> 1, 617, "1234 >> 1");
	test(4 << 2, 16, "4 << 2");
	test(1000 << 1, 2000, "1000 << 1");
	test(1001 % 10, 1, "1001 % 10");
	test(3 % 10, 3, "3 % 10");
	test(10 % 4, 2, "10 % 4");
	test(1000 / 5, 200, "1000 / 5");
	test(3 / 10, 0, "3 / 10");
	test(10 / 3, 3, "10 / 3");
	test(1000 == 32767, 0, "1000 == 32767");
	test(1000 == 1000, 1, "1000 == 1000");
	test(1 != 0, 1, "1 != 0");
	test(1 < -1, 0, "1 < -1");
	test(1 < 2, 1, "1 < 2");
	test(1 != 1, 0, "1 != 1");
/*
	test(2 && 1, 1, "2 && 1");
	test(0 && 1, 0, "0 && 1");
	test(1 && 0, 0, "1 && 0");
	test(0 && 0, 0, "0 && 0");
	test(1000 || 1, 1, "1000 || 1");
	test(1000 || 0, 1, "1000 || 0");
	test(0 || 1, 1, "0 || 1");
	test(0 || 0, 0, "0 || 0");
	test(!2, 0, "!2");
	test(!0, 1, "!0");
 */
	test(~1, -2, "~1");
	test(2 ^ 1, 3, "2 ^ 1");
	test(0 ^ 0, 0, "0 ^ 0");
	test(1 ^ 1, 0, "1 ^ 1");
	test(5 ^ 6, 3, "5 ^ 6");
/*
	test((0 < 1) ? 1 : 0, 1, "(0 < 1) ? 1 : 0");
	test((1000 > 1000) ? 0: 1, 1, "(1000 > 1000) ? 0 : 1");
 */
	puts("ending test\n\r");
}
