UNIASM = ../DEVEL/uniasm

all: $(UNIASM)		\
    BROM601.CMD		\
    BROM601.MEM		\
    BIOS601.CMD

$(UNIASM):
	make -C $(shell dirname $(UNIASM)) $(shell basename $(UNIASM))

.SUFFIXES: .ASM .CMD .MEM

.ASM.CMD: ../DEVMAP.INC ../BOOTROM.INC
	$(UNIASM) $< $(basename $@) $@

.CMD.MEM:
	hexdump -v -e '"  db  " 16/1 "$$%02x, " "\n"' $< | sed 's/,$$//' > $@
#	hexdump -v -e '"%04_ax: " 16/1 "%02x " "\n"' $< > $@

clean:
	rm -f *.CMD *.LST *.MEM
