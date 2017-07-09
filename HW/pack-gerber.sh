#!/bin/bash

topdir=$PWD

name=$1

tmpdir=/tmp/gerb-$$/gerber-$name

mkdir -p $tmpdir

mv ${name}.cmp ${name}.drd ${name}.dri ${name}.gpi ${name}.plc ${name}.pls ${name}.sol ${name}.stc ${name}.sts $tmpdir

pushd $(dirname $tmpdir)

zip -r9 ${topdir}/gerber-${name}.zip gerber-$name

popd
