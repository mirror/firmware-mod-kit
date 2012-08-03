#!/bin/bash

FSIMG="$1"
ROOTFS="$2"
ENDIANESS="$3"
MKFS=""

function finish
{
	rm -f "$FSIMG.le"
	echo "MKFS=\"$MKFS\""
	exit 0
}

if [ "$FSIMG" == "" ] || [ "$FSIMG" == "-h" ]
then
	echo "Usage: $(basename $0) <cramfs image> [output directory] [-be | -le]\n"
	exit 1
fi

if [ $UID -ne 0 ]
then
	SUDO="sudo"
fi

if [ "$ROOTFS" == "" ]
then
	ROOTFS="cramfs-root"
fi

if [ "$ENDIANESS" == "-be" ]
then
	./src/cramfsswap/cramfsswap "$FSIMG" "$FSIMG.le"
else
	cp "$FSIMG" "$FSIMG.le"
fi

$SUDO ./src/cramfs-2.x/cramfsck -x "$ROOTFS" "$FSIMG.le" 2>/dev/null
if [ $? -eq 0 ]
then
	MKFS="./src/cramfs-2.x/mkcramfs"
	finish
fi

$SUDO ./src/uncramfs/uncramfs "$ROOTFS" "$FSIMG.le" 2>/dev/null
if [ $? -eq 0 ]
then
	MKFS="./src/cramfs-2.x/mkcramfs"
	finish
fi

$SUDO ./src/uncramfs-lzma/uncramfs-lzma "$ROOTFS" "$FSIMG.le" 2>/dev/null
if [ $? -eq 0 ]
then
	# Does not exist, will not be able to re-build the file system!
	MKFS="./src/uncramfs-lzma/mkcramfs-lzma"
	finish
fi

echo "File extraction failed!"
exit 1
