#!/bin/bash

DIR="$1"

if [ "$DIR" == "" ]
then
	DIR="fmk"
fi

eval $(cat shared-ng.inc)
eval $(cat $CONFLOG)

FSOUT="newfs.$FS_TYPE"
FWOUT="fw.img"

echo "Building new $FS_TYPE file system..."
$MKFS $ROOTFS $FSOUT

cp $KERNEL $FWOUT
cat $FSOUT >> $FWOUT
if [ -e $FOOTER ]
then
	cat $FOOTER >> $FWOUT
fi

echo "Build $HEADER_TYPE header now..."
