#!/bin/sh
. "./shared.inc"
VERSION='0.45 beta'
#
# Title: build_firmware.sh
# Author: Jeremy Collake <jeremy.collake@gmail.com>
# Site: http://www.bitsum.com
#
# Script to build a cybertan format firmware
# with a squashfs-lzma filesystem.
#
# See documentation at:
#  http://www.bitsum.com/firmware_mod_kit.htm
#
# USAGE: build_firmware.sh OUTPUT_DIRECTORY/ WORKING_DIRECOTRY/
#
# This scripts builds the firmware image from [WORKING_DIRECTORY],
# with the following subdirectories:
#
#    image_parts/   <- firmware seperated
#    rootfs/ 	    <- filesystem
#
# Example:
#
# ./build_firmware.sh new_firmwares/ std_generic/
#
#
FIRMARE_BASE_NAME=custom_image
EXIT_ON_FS_PROBLEM="0"

echo "$0 v$VERSION, (c)2006 Jeremy Collake"

#################################################################
# Build_WRT_Images( OutputDir, WorkingDir )
#################################################################
Build_WRT_Images ()
{
	echo "  Building squashfs-lzma filesystem ..."
	if [ -e "$2/image_parts/squashfs-lzma-image-3_0" ]; then	
		# -magic to fix brainslayer changing squashfs signature in 08/10/06+ firmware images
	 	"src/squashfs-3.0/mksquashfs-lzma" "$2/rootfs/" "$2/image_parts/squashfs-lzma-image-new" \
		-noappend -root-owned -le -magic "$2/image_parts/squashfs_magic" >> build.log
		if [ $? != 0 ]; then
			echo "  ERROR - mksquashfs failed."
			exit 1	
		fi
	else
		echo "  ERROR - Working directory contains no sqfs filesystem?"
		exit 1
	fi	
	#################################################################
	echo "  Building base firmware image (generic) ..."	
	# I switched to asustrx due to bug in trx with big endian OS X. Without version specification it won't 
 	#  add addversion type headers at the end.
	"src/asustrx" -o "$1/$FIRMARE_BASE_NAME.trx" \
		"$2/image_parts/segment1" "$2/image_parts/segment2" \
		"$2/image_parts/squashfs-lzma-image-new" \
			>> build.log 2>&1
	echo "  Building base firmware image (asus) ..."	
	"src/asustrx" -p WL500gx -v 1.9.2.7 -o "$1/$FIRMARE_BASE_NAME-asus.trx" \
		"$2/image_parts/segment1" "$2/image_parts/segment3" \
		"$2/image_parts/squashfs-lzma-image-new" \
		 >> build.log 2>&1
	echo "  Making $1/$FIRMARE_BASE_NAME-wrtsl54gs.bin"
	"src/addpattern" -4 -p W54U -v v4.20.6 -i "$1/$FIRMARE_BASE_NAME.trx" \
		 -o "$1/$FIRMARE_BASE_NAME-wrtsl54gs.bin" -g >> build.log 2>&1
	echo "  Making $1/$FIRMARE_BASE_NAME-wrt54g.bin"
	"src/addpattern" -4 -p W54G -v v4.20.6 -i "$1/$FIRMARE_BASE_NAME.trx" \
		-o "$1/$FIRMARE_BASE_NAME-wrt54g.bin" -g >> build.log 2>&1
	echo "  Making $1/$FIRMARE_BASE_NAME-wrt54gs.bin"
	"src/addpattern" -4 -p W54S -v v4.70.6 -i "$1/$FIRMARE_BASE_NAME.trx" \
		-o "$1/$FIRMARE_BASE_NAME-wrt54gs.bin" -g >> build.log 2>&1
	echo "  Making $1/$FIRMARE_BASE_NAME-wrt54gsv4.bin"
	"src/addpattern" -4 -p W54s -v v1.05.0 -i "$1/$FIRMARE_BASE_NAME.trx" \
		-o "$1/$FIRMARE_BASE_NAME-wrt54gsv4.bin" -g >> build.log 2>&1
	echo "  Making $1/$FIRMARE_BASE_NAME-generic.bin"
	mv "$1/$FIRMARE_BASE_NAME.trx" "$1/$FIRMARE_BASE_NAME-generic.bin" >> build.log 2>&1
}
#################################################################

#################################################################
#################################################################

if [ $# = 2 ]; then
	sh ./check_for_upgrade.sh
	#################################################################
	PlatformIdentify 
	#################################################################
	TestFileSystemExit "$1" "$2"
	#################################################################
	if [ ! -f "./build_firmware.sh" ]; then
		echo "  ERROR - You must run this script from the same directory as it is in!"
		exit 1
	fi
	#################################################################
	# remove deprecated stuff
	if [ -f "./src/mksquashfs.c" ] || [ -f "mksquashfs.c" ]; then
		DeprecateOldVersion
	fi
	#################################################################
	# Invoke BuildTools, which tries to build everything and then
	# sets up appropriate symlinks.
	#
	BuildTools "build.log"
	#################################################################
	echo "  Preparing output directory $1 ..."
	mkdir -p $1 >> build.log 2>&1
	rm "$1/$FIRMWARE_BASE_NAME*.*" "$1" >> build.log 2>&1
	
	if [ -f "$2/image_parts/segment2" ] && [ -f "$2/image_parts/squashfs-lzma-image-3_0" ]; then
		echo "  Detected WRT squashfs-lzma style."
		Build_WRT_Images "$1" "$2"
	else
		echo "  ERROR: Unknown or unsupported firmware image."
		exit 1
	fi

	echo "  Firmware images built."
	ls -l "$1"
	echo "  All done!"
else
	#################################################################
	echo "  Incorrect usage."
	echo "  USAGE: $0 OUTPUT_DIR WORKING_DIR"
	exit 1
fi
exit 0
