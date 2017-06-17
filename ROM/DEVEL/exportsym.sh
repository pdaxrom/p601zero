#!/bin/bash

awk '/\yproc\y/ { print "\tpublic\t",$1; }' $1
awk '/\<global\y/ { i = 2; while ($i) { split($i, b, ","); print "\tpublic\t", b[1]; i++} }' $1
