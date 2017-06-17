#!/bin/bash

cat CLIB.INC | awk '/\yproc\y/ { print "\tpublic\t",$1; }' > CLIB.EXP
cat CLIB.INC | awk '/\<global\y/ { i = 2; while ($i) { split($i, b, ","); print "\tpublic\t", b[1]; i++} }' >>CLIB.EXP
