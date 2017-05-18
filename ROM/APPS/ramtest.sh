#!/bin/bash

writefile=/tmp/$$$.bin
readfile=/tmp/$$$.bin

dd if=/dev/urandom of=$writefile bs=1 count=53248

../bootloader /dev/ttyUSB0 load $writefile 1000

../bootloader /dev/ttyUSB0 save $readfile 1000 e000
cmp $writefile $readfile && echo "RAM write/read OKAY!"

../bootloader /dev/ttyUSB0 save $readfile 1000 e000
cmp $writefile $readfile && echo "RAM write/read OKAY!"

../bootloader /dev/ttyUSB0 save $readfile 1000 e000
cmp $writefile $readfile && echo "RAM write/read OKAY!"

rm -f $writefile $readfile
