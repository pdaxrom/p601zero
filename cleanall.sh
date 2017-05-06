#!/bin/bash

make -C ROM clean

for o in $(svn status | grep '^?' | awk '{ print $2; }'); do
    rm -rf "$o"
done
