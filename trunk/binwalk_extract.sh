#!/bin/bash

IMG="$1"
DIR="$2"
BINWALK="binwalk"

if [ "$DIR" == "" ]
then
	DIR="fmk"
fi

# Check usage
if [ "$IMG" == "" ] || [ "$IMG" == "-h" ]
then
	echo "Usage: $0 <firmware image>"
	exit 1
fi

if [ -e "$DIR" ]
then
	echo "Directory $DIR already exists! Quitting..."
	exit 1
fi

# Create output directories
mkdir -p "$DIR/logs"
mkdir -p "$DIR/image_parts"

# Define log files
LOGFILE="$DIR/logs/extract.log"
CONFLOG="$DIR/logs/config.log"
BINLOG="$DIR/logs/binwalk.log"

echo "Scanning for headers kernels and file systems..."

# Log binwalk results to a file, disable default filters, add filters to only include
# lzma/gzip signatures and signatures that have the words "filesystem" or "header" in 
# their description. Filter out results whose description/text contains the words "invalid" 
# or "jffs".
$BINWALK -f "$BINLOG" -d -x invalid -x jffs -y gzip -y lzma -y header -y filesystem "$IMG"

# Parse out the first header entry in the binwalk log. This is likely a valid firmware header.
HEADER_OFFSET=$(grep header $BINLOG | head -1 | awk '{print $1}')
HEADER_TYPE=$(grep header $BINLOG | head -1 awk '{print tolower($3)}')
if [ "$HEADER_OFFSET" == "" ]
then
	HEADER_OFFSET="0"
fi
if [ "$HEADER_TYPE" == "" ]
then
	HEADER_TYPE="unknown"
fi

# Parse out the first compressed entry in the binwalk log. This is likely the kernel.
KERNEL_OFFSET=$(grep compress $BINLOG | head -1 | awk '{print $1}')
KERNEL_TYPE=$(grep compress $BINLOG | head -1 | awk '{print tolower($3)}')

# Parse out the first file system entry in the binwalk log. This is likely the primary file system.
FS_OFFSET=$(grep filesystem $BINLOG | head -1 | awk '{print $1}')
FS_TYPE=$(grep filesystem $BINLOG | head -1 | awk '{print tolower($3)}')

# Debug messages
echo "Possible $HEADER_TYPE firmware header at offset $HEADER_OFFSET"
echo "Possible $KERNEL_TYPE kernel at offset $KERNEL_OFFSET"
echo "Possible $FS_TYPE file system at offset $FS_OFFSET"

# dd out the image header, compressed kernel, and file system
dd if="$IMG" bs=$KERNEL_OFFSET count=1 of="$DIR/image_parts/header.$HEADER_TYPE"
dd if="$IMG" bs=1 skip=$KERNEL_OFFSET count=$(echo "$FS_OFFSET-$KERNEL_OFFSET" | bc -l) of="$DIR/image_parts/kernel.$KERNEL_TYPE"
dd if="$IMG" bs=$FS_OFFSET skip=1 of="$DIR/image_parts/fs.$FS_TYPE"

# Log the parse values to the CONFLOG for use when re-building the firmware
echo "HEADER_TYPE=$HEADER_TYPE" >> $CONFLOG
echo "HEADER_OFFSET=$HEADER_OFFSET" >> $CONFLOG
echo "KERNEL_TYPE=$KERNEL_TYPE" >> $CONFLOG
echo "KERNEL_OFFSET=$KERNEL_OFFSET" >> $CONFLOG
echo "FS_TYPE=$FS_TYPE" >> $CONFLOG
echo "FS_OFFSET=$FS_OFFSET" >> $CONFLOG

# Extract the file system
case $FS_TYPE in
	"squashfs")
		echo "Extracting SquashFS file system..."
		./unsquashfs_all.sh "$DIR/image_parts/fs.$FS_TYPE" "$DIR/rootfs" >> $LOGFILE
		;;
	"cramfs")
		echo "Extracting CramFS file system..."
		./src/cramfs-2.x/cramfsck -x "$DIR/rootfs" "$DIR/image_parts/fs.$FS_TYPE" >> $LOGFILE
		;;
esac

# Check if file system extraction was successful
if [ $? == 0 ]
then
	echo "Firmware extraction successful!"
	EXIT=0
else
	echo "Firmware extraction failed!"
	EXIT=1
fi

echo "Firmware parts can be found in '$DIR/*'"
exit $EXIT

