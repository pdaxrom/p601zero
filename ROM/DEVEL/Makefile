all: uniasm unilib unilink unic CLIB.OBJ LIBROM.OBJ

.SUFFIXES: .pas .ASM .OBJ .EXP .INC

.pas:
	fpc -g -gl $<

#CLIB.EXP: CLIB.INC
#	./exportsym.sh $< > $@

.INC.EXP:
	./exportsym.sh $< > $@

CLIB.OBJ: CLIB.EXP

LIBROM.OBJ: LIBROM.EXP

.ASM.OBJ:
	./uniasm $< $(basename $@) $@

clean:
	rm -f *.o uniasm unilib unilink unic *.EXP *.OBJ *.LST
