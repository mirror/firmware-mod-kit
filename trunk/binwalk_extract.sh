#!/bin/bash

IMG="$1"
DIR="$2"

if [ "$DIR" == "" ]
then
	DIR="fmk"
fi

BINWALK="binwalk"
LOGFILE="$DIR/logs/binwalk.log"

if [ "$IMG" == "" ] || [ "$IMG" == "-h" ]
then
	echo "Usage: $0 <firmware image>"
	exit 1
fi

mkdir -p "$DIR/logs"
mkdir -p "$DIR/image_parts"

echo "Scanning for kernels and file systems..."

# Log binwalk results to a file, disable default filters, add filters to only include
# lzma/gzip signatures and signatures that have the word "filesystem" in their description.
# Filter out results whose description/text contains the word "invalid" or "jffs".
$BINWALK -f "$LOGFILE" -d -x invalid -x jffs -y gzip -y lzma -y filesystem "$IMG"

KERNEL_OFFSET=$(grep compress $LOGFILE | head -1 | awk '{print $1}')
KERNEL_TYPE=$(grep compress $LOGFILE | head -1 | awk '{print tolower($3)}')

FS_OFFSET=$(grep filesystem $LOGFILE | head -1 | awk '{print $1}')
FS_TYPE=$(grep filesystem $LOGFILE | head -1 | awk '{print tolower($3)}')

echo "Possible $KERNEL_TYPE kernel at offset $KERNEL_OFFSET"
echo "Possible $FS_TYPE file system at offset $FS_OFFSET"

dd if="$IMG" bs=$KERNEL_OFFSET skip=1 of="$DIR/image_parts/kernel.$KERNEL_TYPE"
dd if="$IMG" bs=$FS_OFFSET skip=1 of="$DIR/image_parts/fs.$FS_TYPE"

if [ "$FS_TYPE" == "squashfs" ]
then
	echo "Extracting SquashFS file system..."
	./unsquashfs_all.sh "$DIR/image_parts/fs.$FS_TYPE" "$DIR/rootfs"
fi
