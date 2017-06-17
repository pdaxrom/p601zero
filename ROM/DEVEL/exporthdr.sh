#!/bin/bash

awk '/\yequ|EQU\y/ { print "#define\t"$1"\t"$3; }' $1
