#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <errno.h>

#define BAUDRATE B115200
#define MODEMDEVICE "/dev/ttyUSB0"
#define _POSIX_SOURCE 1 /* POSIX compliant source */
#define FALSE 0
#define TRUE 1

volatile int STOP=FALSE; 

void dumpreg(unsigned char *buf)
{
    int i;
    for (i = 0; i < 16; i++) {
	printf("%02X ", buf[i]);
    }
    printf("\n");
}

int main(int argc, char *argv[])
{
    int fd, res;
    char buf[255];

    struct termios tty;
    struct termios tty_old;
    memset (&tty, 0, sizeof tty);


    fd = open(argv[1], O_RDWR | O_NOCTTY); 

    if (fd <0) {
	perror(MODEMDEVICE);
	exit(-1);
    }

    if ( tcgetattr(fd, &tty) != 0 ) {
	fprintf(stderr, "error %d from tcgetattr\n", errno);
    }

    /* Save old tty parameters */
    tty_old = tty;

    /* Set Baud Rate */
    cfsetospeed (&tty, (speed_t)BAUDRATE);
    cfsetispeed (&tty, (speed_t)BAUDRATE);

    /* Setting other Port Stuff */
    tty.c_cflag     &=  ~PARENB;            // Make 8n1
    tty.c_cflag     &=  ~CSTOPB;
    tty.c_cflag     &=  ~CSIZE;
    tty.c_cflag     |=  CS8;

    tty.c_cflag     &=  ~CRTSCTS;           // no flow control
    tty.c_cc[VMIN]   =  1;                  // read doesn't block
    tty.c_cc[VTIME]  =  5;                  // 0.5 seconds read timeout
    tty.c_cflag     |=  CREAD | CLOCAL;     // turn on READ & ignore ctrl lines

    /* Make raw */
    cfmakeraw(&tty);

    /* Flush Port, then applies attributes */
    tcflush(fd, TCIFLUSH);
    if ( tcsetattr(fd, TCSANOW, &tty ) != 0) {
	fprintf(stderr, "error %d from tcsetattr\n", errno);
    }

    FILE *inf = fopen(argv[2], "rb");

    if (inf) {
	unsigned char *buf;
	fseek(inf, 0, SEEK_END);
	size_t len = ftell(inf);
	fseek(inf, 0, SEEK_SET);
	buf = malloc(len);
	fread(buf, 1, len, inf);
	if (!memcmp(buf, "YM3!", 4)) {
	    int offset = (len - 4) / 14;
	    printf("%d samples\n", offset);
	    int n;
	    for (n = 0; n < offset; n++) {
		int i;
		for (i = 0; i < 14; i++) {
		    write(fd, &buf[4 + offset * i + n], 1);
		}
		write(fd, buf, 2); // r14 and r15
		usleep(20 * 1000);
	    }
	} else {
	    fprintf(stderr, "Unsupported format!\n");
	}
	fclose(inf);
    } else {
	fprintf(stderr, "Can't open file!\n");
    }

    tcsetattr(fd, TCSANOW, &tty_old);

    return 0;
}

