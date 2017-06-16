#define LED_8BIT	0xE6A0
#define LED_2RGB	0xE6A1
#define LED_HEX		0xE6A2
#define INPUT_SWKEYS	0xE6A3

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
