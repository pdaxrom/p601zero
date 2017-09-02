#include <stdio.h>
#include <stdlib.h>

#define INIT_ADDR 0x0100

unsigned short chksum;

void chksum_init()
{
    chksum = 0xff;
}

void chksum_upd(unsigned char b)
{
    chksum -= b;
}

unsigned char chksum_get()
{
    return chksum & 0xff;
}

int main(int argc, char **argv)
{

    FILE  *fd;
    int c, len;
    unsigned short addr = INIT_ADDR;
    unsigned char buf[32];

    if(argc < 2) {
	fprintf(stderr,"no input file specified\n");
	exit(1);
    }
    if(argc > 2) {
	fprintf(stderr,"too many input files (more than one) specified\n");
	exit(1);
    }

    fd = fopen( argv[1], "rb" );
    if (fd == NULL) {
	fprintf(stderr,"failed to open input file: %s\n",argv[1]);
	exit(1);
    }

    while ((len = fread(buf, 1, sizeof(buf), fd)) > 0) {
		int i = 0;
                chksum_init();
                printf("S1%.2X%.4X", len + 3, addr);
		chksum_upd(len + 3);
		chksum_upd(addr >> 8);
		chksum_upd(addr);
                while (i < len) {
                        printf("%.2X", buf[i]);
                        chksum_upd(buf[i]);
                        i++;
                }

                printf("%.2X\r\n", chksum_get());
                addr += sizeof(buf);
    }

    chksum_init();
    chksum_upd(3);
    chksum_upd(INIT_ADDR >> 8);
    chksum_upd(INIT_ADDR);
    printf("S903%.4X%.2X\r\n", INIT_ADDR, chksum_get());

    return 0;
}
