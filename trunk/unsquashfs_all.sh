#!/bin/bash
# Script to attempt to extract files from a SquashFS image using all of the available unsquashfs utilities in FMK until one is successful.
#
# Craig Heffner
# 27 August 2011

IMG="$1"
DIR="$2"

ROOT="./src"
SUBDIRS="squashfs-2.1-r2 squashfs-3.0 squashfs-3.0-lzma-damn-small-variant others/squashfs-3.0-e2100 others/squashfs-3.2-r2 others/squashfs-3.2-r2-lzma others/squashfs-3.2-r2-lzma/squashfs3.2-r2/squashfs-tools others/squashfs-3.3 others/squashfs-3.3-lzma/squashfs3.3/squashfs-tools others/squashfs-4.0-lzma others/squashfs-4.0-realtek"
TIMEOUT="5"
MKFS=""
DEST=""

if [ "$IMG" == "" ] || [ "$IMG" == "-h" ]
then
	echo "Usage: $0 <squashfs image> [output directory]"
	exit 1
fi

if [ "$DIR" == "" ]
then
	DIR="squashfs-root"
fi

DEST="-dest $DIR"

for SUBDIR in $SUBDIRS
do
	unsquashfs="$ROOT/$SUBDIR/unsquashfs"
	mksquashfs="$ROOT/$SUBDIR/mksquashfs"

	if [ -e $unsquashfs ]
	then
		echo -ne "\nTrying $unsquashfs... "

		$unsquashfs $DEST $IMG 2>/dev/null &
		sleep $TIMEOUT && kill $! 1>&2 >/dev/null

		if [ -d "$DIR" ]
		then
			MKFS="$mksquashfs"
		fi
	fi
	
	if [ "$MKFS" == "" ] && [ -e $unsquashfs-lzma ]
	then
		echo -ne "\nTrying $unsquashfs-lzma... "

		$unsquashfs-lzma $DEST $IMG 2>/dev/null &
		sleep $TIMEOUT && kill $! 1>&2 >/dev/null
		
		if [ -d "$DIR" ]
                then
                        MKFS="$mksquashfs-lzma"
                fi
	fi

	if [ "$MKFS" != "" ]
	then
		echo "File system sucessfully extracted!"
		echo "MKFS=\"$MKFS\""
		exit 0
	fi
done

echo "File extraction failed!"
exit 1
