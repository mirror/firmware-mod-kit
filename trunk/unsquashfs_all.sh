#!/bin/bash
# Script to attempt to extract files from a SquashFS image using all of the available unsquashfs utilities in FMK until one is successful.
#
# Craig Heffner
# 27 August 2011

IMG="$1"
DIR="$2"

ROOT="./src"
SUBDIRS="squashfs-2.1-r2 squashfs-3.0 squashfs-3.0-lzma-damn-small-variant others/squashfs-3.2-r2 others/squashfs-3.2-r2-lzma others/squashfs-3.2-r2-lzma/squashfs3.2-r2/squashfs-tools others/squashfs-3.3 others/squashfs-3.3-lzma/squashfs3.3/squashfs-tools"
EXE=""
DEST=""

if [ "$IMG" == "" ] || [ "$IMG" == "-h" ]
then
	echo "Usage: $0 <squashfs image> [output directory]"
	exit 1
fi

if [ "$DIR" != "" ]
then
	DEST="-dest $DIR"
fi

for SUBDIR in $SUBDIRS
do
	unsquashfs="$ROOT/$SUBDIR/unsquashfs"

	if [ -e $unsquashfs ]
	then
		echo -n "$unsquashfs: "
		$unsquashfs $DEST $IMG
		
		if [ $? == 0 ]
		then
			EXE=$unsquashfs
		fi
	fi
	
	if [ "$EXE" == "" ] && [ -e $unsquashfs-lzma ]
	then
		echo -n "$unsquashfs-lzma: "
		$unsquashfs-lzma $DEST $IMG
        
                if [ $? == 0 ]
                then
                        EXE="$unsquashfs-lzma"
                fi
	fi

	if [ "$EXE" != "" ]
	then
		echo "File system sucessfully extracted ($EXE)"
		exit 0
	fi
done

echo "File extraction failed!"
exit 1
