UNIASM = ../DEVEL/uniasm

all: $(UNIASM)		\
    IRQTEST.CMD		\
    RAMCHK.CMD		\
    RAMTEST.CMD		\
    RAMPAGECHK.CMD	\
    VIDEOMODES.CMD	\
    VPUDMATEST.CMD	\
    VIDEODRV.CMD	\
    MICROBASIC.CMD	\
    MICROBASICPLUS.CMD	\
    RAMTESTINT.CMD		\
    ymstreamer

$(UNIASM):
	make -C $(shell dirname $(UNIASM)) $(shell basename $(UNIASM))

.SUFFIXES: .ASM .CMD

.ASM.CMD: ../DEVMAP.INC ../BOOTROM.INC
	$(UNIASM) $< $(basename $@) $@

clean:
	rm -f *.LST *.CMD ymstreamer
