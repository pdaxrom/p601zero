all: uniasm unilib unilink unic CLIB.OBJ

.SUFFIXES: .pas .ASM .OBJ

.pas:
	fpc -g -gl $<

CLIB.EXP: CLIB.INC
	./exportsym.sh $< > $@

CLIB.OBJ: CLIB.EXP

.ASM.OBJ:
	./uniasm $< $(basename $@) $@

clean:
	rm -f *.o uniasm unilib unilink unic CLIB.EXP CLIB.OBJ CLIB.LST
