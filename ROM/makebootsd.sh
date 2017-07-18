#!/bin/bash

dd if=/dev/mmcblk0 of=/tmp/bsec.bin bs=62 count=1
cat /tmp/bsec.bin BOOTSEC.CMD >/dev/mmcblk0
