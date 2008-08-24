#!/bin/sh
# (c)2008 Jeremy Collake
# Bitsum Technologies http://www.bitsum.com
# Released under GPL license
if [ $(id -u) != "0" ]; then
	echo "ERROR: This script should be run as root to create necessary devices!"
	exit 1
fi
if [ $# = 2 ]; then

	if [ ! -e "../src/squashfs-3.0/unsquashfs-lzma" ]; then	
		make -C "../src" 2>&1 > buildlog.log
		if [ ! -e "../src/squashfs-3.0/unsquashfs-lzma" ]; then
			echo "Error building unsquashfs-lzma! Check buildlog.log"
			exit 1
		fi	
	fi

	PARTS_PATH=$2
	echo "Extracting $1 to $2 ..."
	mkdir -p "$PARTS_PATH"
	if [ $? = 0 ]; then
 		dd "if=$1" "of=$PARTS_PATH/vmlinuz" bs=1K count=1024
 		dd "if=$1" "of=$PARTS_PATH/squashfs-3-lzma.img" bs=1K skip=1024
		filesize=$(du -b $1 | cut -f 1)
		filesize=$((filesize - 24))
		dd "if=$1" "of=$PARTS_PATH/hwid.txt" bs=1 skip=$filesize
		"../src/squashfs-3.0/unsquashfs-lzma" "$PARTS_PATH/squashfs-3-lzma.img" -dest "$PARTS_PATH/rootfs_extracted"			
	else
		echo "ERROR: Creating output directory.."
	fi
else
	echo "ERROR: Improper usage."
	echo "Usage: $0 firmware_image.rom working_output_dir/"
	exit 1
fi

