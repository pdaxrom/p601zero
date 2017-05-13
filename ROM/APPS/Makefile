all: DEMO1.CMD

DEMO1.CMD: DEMO1.ASM
	../6803 $^ ROM.LST $@

clean:
	rm -f *.LST *.CMD
