UNIASM		= ../DEVEL/uniasm
UNILIB		= ../DEVEL/unilib
UNILINK		= ../DEVEL/unilink

UNIC = ../DEVEL/unic

CC = $(UNIC)

all: $(UNIC) hello1.cmd
#hello2.cmd hello3.cmd hello4.cmd hello5.cmd hello6.cmd hello7.cmd hello8.cmd hello9.cmd hello10.cmd optest.cmd gpio.cmd

$(UNIC):
	make -C $(shell dirname $(UNIASM))

CFLAGS = -fc -fo -fb

.SUFFIXES: .asm .cmd

.asm.cmd: ../DEVMAP.INC ../BOOTROM.INC CLIB.INC
	$(UNIASM) $< $(basename $@) $@

.c.asm:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f *.asm *.obj *.lst *.cmd *.LST *.CMD *.ERR
