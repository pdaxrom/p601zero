all: hello2.cmd hello3.cmd hello4.cmd hello5.cmd hello6.cmd hello7.cmd hello8.cmd hello9.cmd hello10.cmd optest.cmd gpio.cmd

CC = ./c6801

CFLAGS = -fc -fo

.SUFFIXES: .asm .cmd

.asm.cmd: ../DEVMAP.INC ../BOOTROM.INC CLIB.INC
	../uniasm $< $(basename $@) $@

.c.asm:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f *.asm *.obj *.lst *.cmd *.LST *.CMD *.ERR
