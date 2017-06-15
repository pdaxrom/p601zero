foo(a, b)
char a;
char b;
{
    puthex(a);
    puthex(b);
}

main()
{
    char a;

    a = -1;

    puthex(a);
    puts("Hello, World!\n");

    foo(2, 255^a);
    return 0;
}
