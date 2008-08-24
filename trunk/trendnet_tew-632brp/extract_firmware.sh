#!/bin/sh
#
# Script by Jeremy Collake <jeremy.collake@gmail.com> 
#
if [ $# = 2 ]; then
	PARTS_PATH=$2
	echo "Extracting $1 to $2 ..."
	mkdir -p "$PARTS_PATH"
	if [ $? = 0 ]; then
 		dd "if=$1" "of=$PARTS_PATH/vmlinuz" bs=1K count=1024
 		dd "if=$1" "of=$PARTS_PATH/squashfs-3-lzma.img" bs=1K skip=1024
		# todo: must extract hardware image tag.. 
		#  asssume last 24 bytes, or can assume squashfs is 
		#  aligned (its not for all images though)
	else
		echo "ERROR: Creating output directory.."
	fi
else
	echo "ERROR: Improper usage."
	echo "Usage: $0 firmware_image.rom image_parts_output/"
	exit 1
fi

