foo(a, b)
char a;
char b;
{
    putc(a);
    putc(b);
}

main()
{
    puts("Hello, World!\n");
    foo(48, 49);
    return 0;
}
