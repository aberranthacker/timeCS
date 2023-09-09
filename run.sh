#!/bin/sh

make -s

echo starting UKNCBTL
~/opt/QtUkncBtl/QtUkncBtl -boot1 -disk0:dsk/timeCS.dsk

echo done
