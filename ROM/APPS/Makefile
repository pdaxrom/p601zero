all: DEMO1.CMD IRQTEST.CMD

.SUFFIXES: .ASM .CMD

.ASM.CMD:
	../6803 $< $(basename $@) $@

clean:
	rm -f *.LST *.CMD
