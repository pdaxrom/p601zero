all: uniasm unilib unilink unic CLIB.OBJ LIBROM.OBJ CRT0.OBJ DEVMAP.H BOOTROM.H

.SUFFIXES: .pas .ASM .OBJ .EXP .INC

.pas:
	fpc -g -gl $<

#CLIB.EXP: CLIB.INC
#	./exportsym.sh $< > $@

.INC.EXP:
	./exportsym.sh $< > $@

.INC.H:
	./exporthdr.sh ../$< > $@

CLIB.OBJ: CLIB.EXP

LIBROM.OBJ: LIBROM.EXP

.ASM.OBJ:
	./uniasm $< $(basename $@) $@

BOOTROM.H: ../BOOTROM.INC
	./exporthdr.sh $< > $@

DEVMAP.H: ../DEVMAP.INC
	./exporthdr.sh $< > $@

clean:
	rm -f *.o uniasm unilib unilink unic *.EXP *.OBJ *.LST DEVMAP.H BOOTROM.H
