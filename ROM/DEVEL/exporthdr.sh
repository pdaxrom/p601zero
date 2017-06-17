#!/bin/bash

awk '/\yequ|EQU\y/ { print "#define\t"$1"\t"$3; }' $1 | \
    awk '{ tmp=match($0, /\$[0-9A-Za-z]+/); if (tmp != 0) print substr($0,0,tmp-1)"0x"substr($0,tmp+1,length($0)-tmp); else print $0; }'
