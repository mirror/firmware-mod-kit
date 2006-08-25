#!/bin/sh
. "./shared.inc"
VERSION='0.43 beta'
#
# Title: extract_firmware.sh
# Author: Jeremy Collake <jeremy.collake@gmail.com>
# Site: http://www.bitsum.com
#
# Script to extract a cybertan format firmware
# with a squashfs-lzma filesystem.
#
# See documentation at:
#  http://www.bitsum.com/firmware_mod_kit.htm
#
# USAGE: extract_firmware.sh FIRMWARE_IMAGE.BIN WORKING_DIRECTORY/
#
# This scripts extacts the firmware image to [WORKING_DIRECTORY],
# with the following subdirectories:
#
#    image_parts/   <- firmware seperated
#    rootfs/ 	    <- extracted filesystem
#
# Example:
#
# ./extract_firmware.sh dd-wrt.v23_generic.bin std_generic
#
#
EXIT_ON_FS_PROBLEM="0"

echo "$0 v$VERSION, (c)2006 Jeremy Collake"

#################################################################
#################################################################

if [ $# = 2 ]; then
	#################################################################
	PlatformIdentify
	#################################################################
	TestFileSystemExit $1 $2
	#################################################################
	if [ -f "$1" ]; then
		if [ ! -e "./extract_firmware.sh" ]; then
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
		BuildTools "extract.log"				     					
		#################################################################		
		echo "  Preparing working directory ..."
		echo "   Removing any previous files ..."
		rm -rf "$2/rootfs" >> extract.log 2>&1
		rm -rf "$2/image_parts" >> extract.log 2>&1
		rm -rf "$2/installed_packages" >> extract.log 2>&1
		echo "   Creating directories ..."
		mkdir -p "$2/image_parts" >> extract.log 2>&1
		mkdir -p "$2/installed_packages" >> extract.log 2>&1
		echo "  Extracting firmware ..."
		"src/untrx" "$1" "$2/image_parts" >> extract.log
		if [ -f "$2/image_parts/squashfs-lzma-image" ]; then	
	 		"src/squashfs-3.0/unsquashfs-lzma" \
			-dest "$2/rootfs" "$2/image_parts/squashfs-lzma-image" >> extract.log	
		else
			echo "  Error extracting firmware. Check extract.log."
			exit 1
		fi
		if [ -e "$2/rootfs" ]; then
			echo "  Firmware appears extracted correctly!"
			echo "  Now make changes and run build_firmware.sh."
		else
			echo "  Error: Squashfs filesystem not extracted properly."
			echo "  Make sure the firmware image format is right."
			exit 1
		fi	
	else
		echo "  $1 does not exist.. give me something to work with man!"
	fi
else
	echo "  Incorrect usage."
	echo "  USAGE: $0 FIRMWARE_IMAGE.BIN WORKING_DIR"
	exit 1
fi
exit 0
