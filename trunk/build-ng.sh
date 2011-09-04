#!/bin/bash

DIR="$1"

if [ "$DIR" == "" ]
then
	DIR="fmk"
fi

eval $(cat shared-ng.inc)
eval $(cat $CONFLOG)

FSOUT="$DIR/newfs.$FS_TYPE"
FWOUT="$DIR/fw.img"

echo "Building new $FS_TYPE file system..."

# Build the appropriate file system
case $FS_TYPE in
	"squashfs")
		$MKFS $ROOTFS $FSOUT $ENDIANESS -all-root
		;;
esac

if [ ! -e $FSOUT ]
then
	echo "Unsupported file system ($FS_TYPE), or failed to create new file system. Quitting..."
	exit 1
fi

# Append the new file system to the first part of the original firmware file
cp $HEADER_IMAGE $FWOUT
cat $FSOUT >> $FWOUT

# Calculate and create any filler bytes required between the end of the file system and the footer / EOF.
CUR_SIZE=$(ls -l $FWOUT | awk '{print $5}')
((FILLER_SIZE=$FW_SIZE-$CUR_SIZE-$FOOTER_SIZE-$HEADER_SIZE))
echo "FS FILLER SIZE: $FILLER_SIZE"
perl -e "print \"\xFF\"x$FILLER_SIZE" >> $FWOUT

# Append the footer to the new firmware image, if there is any footer
if [ "$FOOTER_SIZE" -gt "0" ]
then
	cat $FOOTER_IMAGE >> $FWOUT
fi

# Calculate new checksum values for the firmware header
./crcalc/crcalc $FWOUT

if [ $? -eq 0 ]
then
	echo -n "Finished! "
else
	echo -n "Firmware header not supported; firmware checksums may be incorrect. "
fi

echo "New firmware image has been saved to: $FWOUT"
