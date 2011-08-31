#!/bin/bash

IMG="$1"
DIR="$2"

if [ "$DIR" == "" ]
then
	DIR="fmk"
fi

# Import shared settings. $DIR MUST be defined prior to this!
eval $(cat shared-ng.inc)

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

# Get the size, in bytes, of the target firmware image
FW_SIZE=$(ls -l $IMG | cut -d' ' -f5)

# Create output directories
mkdir -p "$DIR/logs"
mkdir -p "$DIR/image_parts"

echo "Scanning firmware..."

# Log binwalk results to a file, disable default filters, add filters to only include
# lzma/gzip signatures and signatures that have the words "filesystem", "header" or 
# "footer" in their description. Filter out results whose description/text contains the 
# word "invalid".
$BINWALK -f "$BINLOG" -d -x invalid -y header -y footer -y squashfs -y cramfs "$IMG"

IFS=$'\n'

# Loop through binwalk log file
for LINE in $(sort -n $BINLOG | grep -v -e '^DECIMAL' -e '^---')
do
	# Get decimal file offset and the first word of the description
	OFFSET=$(echo $LINE | awk '{print $1}')
	DESCRIPTION=$(echo $LINE | awk '{print tolower($3)}')

	# Offset 0 == firmware header
	if [ "$OFFSET" == "0" ]
	then
		HEADER_OFFSET=$OFFSET
		HEADER_TYPE=$DESCRIPTION
		HEADER_SIZE=$(echo $LINE | sed -e 's/.*header size: //' | cut -d' ' -f1)
		((KERNEL_OFFSET=$HEADER_OFFSET+$HEADER_SIZE))

	# Some firmware have two headers
	elif [ "$(echo $LINE | grep -i header)" != "" ]
	then
		HEADER2_OFFSET=$OFFSET
		HEADER2_TYPE=$DESCRIPTION
		HEADER2_SIZE=$(echo $LINE | sed -e 's/.*header size: //' | cut -d' ' -f1)
		((KERNEL_OFFSET=$HEADER2_OFFSET+$HEADER2_SIZE))

	# Check to see if this line is a file system entry
	elif [ "$(echo $LINE | grep -i filesystem)" != "" ]
	then
		FS_OFFSET=$OFFSET
		FS_TYPE=$DESCRIPTION

		# Need to know endianess for re-assembly
		if [ "$(echo $LINE | grep -i 'big endian')" != "" ]
                then
                        ENDIANESS="-be"
                else
                        ENDIANESS="-le"
                fi

	# Check to see if this line is a footer entry
	elif [ "$(echo $LINE | grep -i footer)" != "" ]
	then
		FOOTER_OFFSET=$OFFSET
		FOOTER_TYPE=$DESCRIPTION
	fi
done

if [ "$HEADER_OFFSET" != "0" ]
then
        echo "WARNING: Firmware header not recognized! Will not be able to reassemble firmware image."
fi

if [ "$KERNEL_OFFSET" != "" ]
then
        echo "Extracting kernel image at offset $KERNEL_OFFSET"
        dd if="$IMG" bs=1 skip=$KERNEL_OFFSET count=$(echo "$FS_OFFSET-$KERNEL_OFFSET" | bc -l) of="$KERNEL" 2>/dev/null
else
        echo "WARNING: Kernel location unknown! Will not be able to reassemble firmware image."
fi

if [ "$FS_OFFSET" != "" ]
then
        echo "Extracting $FS_TYPE file system at offset $FS_OFFSET"
        dd if="$IMG" bs=$FS_OFFSET skip=1 of="$FSIMG" 2>/dev/null
else
        echo "ERROR: No supported file system found! Aborting..."
        exit 1
fi

if [ "$FOOTER_OFFSET" != "" ]
then
	echo "Extracting $FOOTER_TYPE footer at offset $FOOTER_OFFSET"
	dd if="$IMG" bs=$FOOTER_OFFSET skip=1 of="$FOOTER" 2>/dev/null
fi

# Log the parsed values to the CONFLOG for use when re-building the firmware
echo "FW_SIZE='$FW_SIZE'" >> $CONFLOG
echo "HEADER_TYPE='$HEADER_TYPE'" >> $CONFLOG
echo "HEADER_SIZE='$HEADER_SIZE'" >> $CONFLOG
echo "HEADER2_TYPE='$HEADER2_TYPE'" >> $CONFLOG
echo "HEADER2_SIZE='$HEADER2_SIZE'" >> $CONFLOG
echo "KERNEL_OFFSET='$KERNEL_OFFSET'" >> $CONFLOG
echo "FS_TYPE='$FS_TYPE'" >> $CONFLOG
echo "FS_OFFSET='$FS_OFFSET'" >> $CONFLOG
echo "ENDIANESS='$ENDIANESS'" >> $CONFLOG

# Extract the file system and save the MKFS variable to the CONFLOG
case $FS_TYPE in
	"squashfs")
		echo "Extracting SquashFS file system..."
		./unsquashfs_all.sh "$FSIMG" "$ROOTFS" 2>/dev/null | grep MKFS >> $CONFLOG
		;;
	"cramfs")
		echo "Extracting CramFS file system..."
		if [ "$ENDIANESS" == "-be" ]
		then
			mv "$FSIMG" "$FSIMG.be"
			cramfsswap "$FSIMG.be" "$FSIMG" && rm "$FSIMG.be"
		fi
		./src/cramfs-2.x/cramfsck -x "$ROOTFS" "$FSIMG"
		echo "MKFS=./src/cramfs-2.x/mkcramfs" >> $CONFLOG
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

