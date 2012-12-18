#!/bin/bash
# Script to attempt to extract files from a SquashFS image using all of the available unsquashfs utilities in FMK until one is successful.
#
# Craig Heffner
# 27 August 2011

IMG="$1"
DIR="$2"

ROOT="./src"
SUBDIRS="squashfs-2.1-r2 \
squashfs-3.0 \
squashfs-3.0-lzma-damn-small-variant \
others/squashfs-2.0-nb4 \
others/squashfs-3.0-e2100 \
others/squashfs-3.2-r2 \
others/squashfs-3.2-r2-lzma \
others/squashfs-3.2-r2-lzma/squashfs3.2-r2/squashfs-tools \
others/squashfs-3.2-r2-hg612-lzma \
others/squashfs-3.2-r2-wnr1000 \
others/squashfs-3.2-r2-rtn12 \
others/squashfs-3.3 \
others/squashfs-3.3-lzma/squashfs3.3/squashfs-tools \
others/squashfs-3.3-grml-lzma/squashfs3.3/squashfs-tools \
others/squashfs-3.4-cisco \
others/squashfs-3.4-nb4 \
others/squashfs-4.0-lzma \
others/squashfs-4.0-realtek \
others/squashfs-4.2 \
others/squashfs-hg55x-bin"
TIMEOUT="15"
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
MAJOR=$(file "$IMG" | sed -e 's/.*version //' | cut -d'.' -f1)

echo -e "Attempting to extract SquashFS $MAJOR.X file system...\n"

for SUBDIR in $SUBDIRS
do
	if [ "$(echo $SUBDIR | grep "$MAJOR\.")" == "" ]
	then
		echo "Skipping $SUBDIR (wrong version)..."
		continue
	fi

	unsquashfs="$ROOT/$SUBDIR/unsquashfs"
	mksquashfs="$ROOT/$SUBDIR/mksquashfs"

	if [ -e $unsquashfs ]
	then
		echo -ne "\nTrying $unsquashfs... "

		$unsquashfs $DEST $IMG 2>/dev/null &
		sleep $TIMEOUT && kill $! 1>&2 >/dev/null

		if [ -d "$DIR" ]
		then
			if [ "$(ls $DIR)" != "" ]
			then
				# Most systems will have busybox - make sure it's a non-zero file size
				if [ -e "$DIR/bin/busybox" ]
				then
					if [ "$(wc -c $DIR/bin/busybox | cut -d' ' -f1)" != "0" ]
					then
						MKFS="$mksquashfs"
					fi
				else
					MKFS="$mksquashfs"
				fi
			fi

			if [ "$MKFS" == "" ]
			then
				rm -rf "$DIR"
			fi
		fi
	fi
	
	if [ "$MKFS" == "" ] && [ -e $unsquashfs-lzma ]
	then
		echo -ne "\nTrying $unsquashfs-lzma... "

		$unsquashfs-lzma $DEST $IMG 2>/dev/null &
		sleep $TIMEOUT && kill $! 1>&2 >/dev/null
		
		if [ -d "$DIR" ]
                then
			if [ "$(ls $DIR)" != "" ]
			then
				# Most systems will have busybox - make sure it's a non-zero file size
				if [ -e "$DIR/bin/busybox" ]
				then
					if [ "$(wc -c $DIR/bin/busybox | cut -d' ' -f1)" != "0" ]
					then
						MKFS="$mksquashfs-lzma"
					fi
				else
                        		MKFS="$mksquashfs-lzma"
				fi
			fi
			
			if [ "$MKFS" == "" ]
			then
				rm -rf "$DIR"
			fi
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
