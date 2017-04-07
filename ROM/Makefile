all: 6803 rom.bin

6803: 6803.PAS
	fpc $^

rom.bin: ROM.ASM
	./6803 ROM.ASM ROM.LST ROM.CMD
	hexdump -v -e '"%04_ax: " 16/1 "%02x " "\n"' ROM.CMD > rom.mem
	cat ROM.CMD > $@

clean:
	rm -f rom.bin *.LST *.CMD 6803 *.o *.mem
