#!/bin/bash

IMG="$1"
DIR="$2"

if [ "$DIR" == "" ]
then
	DIR="fmk"
fi

# Import shared settings. $DIR MUST be defined prior to this!
eval $(cat shared-ng.inc)

echo -e "Firmware Mod Kit (extract-ng) $VERSION, (c)2011 Craig Heffner, Jeremy Collake\nhttp://www.bitsum.com\n"

# Check usage
if [ "$IMG" == "" ] || [ "$IMG" == "-h" ]
then
	echo -e "Usage: $0 <firmware image>\n"
	exit 1
fi

if [ -e "$DIR" ]
then
	echo "Directory $DIR already exists! Quitting..."
	exit 1
fi

# Check if FMK has been built, and if not, build it
if [ ! -e "./src/crcalc/crcalc" ]
then
	echo "Firmware-Mod-Kit has not been built yet. Building..."
	cd src && make

	if [ $? -eq 0 ]
	then
		cd -
	else
		echo "Build failed! Quitting..."
		exit 1
	fi
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
$BINWALK -f "$BINLOG" -d -x invalid -y trx -y uimage -y squashfs "$IMG"

IFS=$'\n'

# Header image offset is ALWAYS 0. Header checksums are simply updated by build-ng.sh.
HEADER_IMAGE_OFFSET=0

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
		HEADER_IMAGE_SIZE=$(echo $LINE | sed -e 's/.*image size: //' | cut -d' ' -f1)

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
	fi
done

# Header image size is everything from the header image offset (0) up to the file system
((HEADER_IMAGE_SIZE=$FS_OFFSET-$HEADER_IMAGE_OFFSET))

if [ "$HEADER_OFFSET" == "0" ] && [ "$HEADER_IMAGE_SIZE" -gt "$HEADER_SIZE" ]
then
        echo "Extracting $HEADER_IMAGE_SIZE bytes of $HEADER_TYPE header image at offset $HEADER_IMAGE_OFFSET"
        dd if="$IMG" bs=$HEADER_IMAGE_SIZE skip=$HEADER_IMAGE_OFFSET count=1 of="$HEADER_IMAGE" 2>/dev/null
else
        echo "WARNING: Firmware header not recognized! Will not be able to reassemble firmware image."
fi

if [ "$FS_OFFSET" != "" ]
then
        echo "Extracting $FS_TYPE file system at offset $FS_OFFSET"
        dd if="$IMG" bs=$FS_OFFSET skip=1 of="$FSIMG" 2>/dev/null
else
        echo "ERROR: No supported file system found! Aborting..."
        exit 1
fi

FOOTER_SIZE=0
FOOTER_OFFSET=0

# Try to determine if there is a footer at the end of the firmware image.
# Grap the last 10 lines of a hexdump of the firmware image. Reverse the line order and
# replace any lines that start with '*' with the word 'FILLER'.
for LINE in $(hexdump -C $IMG | tail -11 | head -10 | sed -n '1!G;h;$p' | sed -e 's/^*/FILLER/')
do
        if [ "$LINE" == "FILLER" ]
        then
                break
        else
                ((FOOTER_SIZE=$FOOTER_SIZE+16))
        fi
done

# If a footer was found, dump it out
if [ "$FOOTER_SIZE" != "0" ]
then
	((FOOTER_OFFSET=$FW_SIZE-$FOOTER_SIZE))
	echo "Extracting $FOOTER_SIZE byte footer from offset $FOOTER_OFFSET"
	dd if="$IMG" bs=1 skip=$FOOTER_OFFSET count=$FOOTER_SIZE of="$FOOTER_IMAGE" 2>/dev/null
else
	FOOTER_OFFSET=$FW_SIZE
fi

# Log the parsed values to the CONFLOG for use when re-building the firmware
echo "FW_SIZE='$FW_SIZE'" >> $CONFLOG
echo "HEADER_TYPE='$HEADER_TYPE'" >> $CONFLOG
echo "HEADER_SIZE='$HEADER_SIZE'" >> $CONFLOG
echo "HEADER_IMAGE_SIZE='$HEADER_IMAGE_SIZE'" >> $CONFLOG
echo "HEADER_IMAGE_OFFSET='$HEADER_IMAGE_OFFSET'" >> $CONFLOG
echo "FOOTER_SIZE='$FOOTER_SIZE'" >> $CONFLOG
echo "FOOTER_OFFSET='$FOOTER_OFFSET'" >> $CONFLOG
echo "FS_TYPE='$FS_TYPE'" >> $CONFLOG
echo "FS_OFFSET='$FS_OFFSET'" >> $CONFLOG
echo "ENDIANESS='$ENDIANESS'" >> $CONFLOG

# Extract the file system and save the MKFS variable to the CONFLOG
case $FS_TYPE in
	"squashfs")
		echo "Extracting squashfs files..."
		./unsquashfs_all.sh "$FSIMG" "$ROOTFS" 2>/dev/null | grep MKFS >> $CONFLOG
		;;
#	"cramfs")
#		echo "Extracting CramFS file system..."
#		if [ "$ENDIANESS" == "-be" ]
#		then
#			mv "$FSIMG" "$FSIMG.be"
#			cramfsswap "$FSIMG.be" "$FSIMG" && rm "$FSIMG.be"
#		fi
#		./src/cramfs-2.x/cramfsck -x "$ROOTFS" "$FSIMG"
#		echo "MKFS=./src/cramfs-2.x/mkcramfs" >> $CONFLOG
#		;;
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

