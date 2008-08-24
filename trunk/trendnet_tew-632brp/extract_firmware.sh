#!/bin/sh
#
# Script by Jeremy Collake <jeremy.collake@gmail.com> 
#
if [ $(id -u) != "0" ]; then
	echo "ERROR: This script should be run as root to create necessary devices!"
	exit 1
fi
if [ $# = 2 ]; then
	PARTS_PATH=$2
	echo "Extracting $1 to $2 ..."
	mkdir -p "$PARTS_PATH"
	if [ $? = 0 ]; then
 		dd "if=$1" "of=$PARTS_PATH/vmlinuz" bs=1K count=1024
 		dd "if=$1" "of=$PARTS_PATH/squashfs-3-lzma.img" bs=1K skip=1024
		filesize=$(du -b $1 | cut -f 1)
		filesize=$((filesize - 24))
		dd "if=$1" "of=$PARTS_PATH/hwid.txt" bs=1 skip=$filesize
	else
		echo "ERROR: Creating output directory.."
	fi
else
	echo "ERROR: Improper usage."
	echo "Usage: $0 firmware_image.rom image_parts_output/"
	exit 1
fi

