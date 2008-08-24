#!/bin/sh
. "./shared.inc"
VERSION='0.51 beta'
#
# Title: extract_firmware.sh
# Author: Jeremy Collake <jeremy.collake@gmail.com>
# Site: http://www.bitsum.com/firmware_mod_kit.htm
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

echo "$0 v$VERSION, (c)2006-2008 Jeremy Collake"

#################################################################
#################################################################

if [ $# = 2 ]; then
	sh ./check_for_upgrade.sh
	#################################################################
	PlatformIdentify
	#################################################################
	TestFileSystemExit $1 $2
	#################################################################
	if [ -f "$1" ]; then
		if [ ! -f "./extract_firmware.sh" ]; then
			echo " ERROR - You must run this script from the same directory as it is in!"
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
		echo " Preparing working directory ..."
		echo "  Removing any previous files ..."
		rm -rf "$2/rootfs" >> extract.log 2>&1
		rm -rf "$2/image_parts" >> extract.log 2>&1
		rm -rf "$2/installed_packages" >> extract.log 2>&1
		echo "  Creating directories ..."
		mkdir -p "$2/image_parts" >> extract.log 2>&1
		mkdir -p "$2/installed_packages" >> extract.log 2>&1
		echo " Extracting firmware ..."
		"src/untrx" "$1" "$2/image_parts" >> extract.log 2>&1
		# if squashfs 3.1 or 3.2, symlink it to 3.0 image, since they are compatible
		if [ -f "$2/image_parts/squashfs-lzma-image-3_1" ]; then	
			ln -s "$2/image_parts/squashfs-lzma-image-3_0"  "$2/image_parts/squashfs-lzma-image-3_1"
		fi
		if [ -f "$2/image_parts/squashfs-lzma-image-3_2" ]; then	
			ln -s "$2/image_parts/squashfs-lzma-image-3_0"  "$2/image_parts/squashfs-lzma-image-3_2"
		fi
		if [ -f "$2/image_parts/squashfs-lzma-image-3_x" ]; then	
			ln -s "$2/image_parts/squashfs-lzma-image-3_0"  "$2/image_parts/squashfs-lzma-image-3_x"
		fi
		# now unsquashfs, if filesystem is squashfs
		if [ -f "$2/image_parts/squashfs-lzma-image-3_0" ]; then	
	 		"src/squashfs-3.0/unsquashfs-lzma" \
			-dest "$2/rootfs" "$2/image_parts/squashfs-lzma-image-3_0" >> extract.log	
		elif [ -f "$2/image_parts/cramfs-image-x_x" ]; then
			TestIsRootAndExitIfNot
			"src/cramfs-2.x/cramfsck" \
				-v -x "$2/rootfs" "$2/image_parts/cramfs-image-x_x" >> extract.log 2>&1			
		else
			echo " Possibly unsupported firmware filesystem image.."
			echo " Error extracting firmware. Check extract.log."
			exit 1
		fi
		if [ -e "$2/rootfs" ]; then
			echo " Firmware appears extracted correctly!"
			echo " Now make changes and run build_firmware.sh."
		else
			echo " Error: filesystem not extracted properly."
			echo "   firmware image format not compatible?"
			exit 1
		fi	
	else
		echo " $1 does not exist.. give me something to work with man!"
	fi
else
	echo " Incorrect usage."
	echo " USAGE: $0 FIRMWARE_IMAGE.BIN WORKING_DIR"
	exit 1
fi
exit 0
