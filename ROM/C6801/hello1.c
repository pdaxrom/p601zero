#asm
    org		$100
    jmp		QZMAIN
    include	../DEVEL/CLIB.INC
    include	../DEVEL/LIBROM.INC
#endasm

main()
{
    puts("Hello, World\n\r");
    return 0;
}
