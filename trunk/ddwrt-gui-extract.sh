#!/bin/bash

DIR="$1"

if [ "$DIR" == "" ]
then
	DIR="fmk/rootfs"
fi

eval $(cat shared-ng.inc)
FILE="$DIR/usr/sbin/httpd"
WEBS="$DIR/etc/www"
GLOBAL="websRomPageIndex"

echo -e "Firmware Mod Kit (ddwrt-gui-extract) $VERSION, (c)2011 Craig Heffner\n"

if [ ! -d "$DIR" ]
then
	echo -e "Usage: $0 [rootfs directory]\n"
	exit 1
fi

if [ ! -e "$FILE" ]|| [ ! -e "$WEBS" ]
then
	echo "Unable to locate httpd / www files in directory $DIR. Quitting..."
	exit 1
fi

# Get the target file's endianess
ENDIANESS=$(readelf --file-header "$FILE" 2>/dev/null | grep endian | sed -e 's/endian.*//' | awk '{print $NF}')

# Get the physical and virtual address of the section where the globals are stored
HEADERRW=$(readelf --program-headers "$FILE" 2>/dev/null | grep LOAD | grep " RW ")
RPHYSADDR=$(echo "$HEADERRW" | awk '{print $2}')
RVIRTADDR=$(echo "$HEADERRW" | awk '{print $3}')

HEADERRE=$(readelf --program-headers "$FILE" 2>/dev/null | grep LOAD | grep " R E ")
SPHYSADDR=$(echo "$HEADERRE" | awk '{print $2}')
SVIRTADDR=$(echo "$HEADERRE" | awk '{print $3}')

# Get the virtual address of the websRomPageIndex global variable
ROMADDR="0x$(readelf --arch-specific "$FILE" 2>/dev/null | grep "$GLOBAL" | awk '{print $4}')"

# Calculate the physical offset of the websRomPageIndex variable
#((OFFSET=$GLOBADDR-$VIRTADDR+$PHYSADDR))

./src/webcomp-tools/webdecomp --$ENDIANESS-endian --virtual-rom-section=$(($RVIRTADDR)) --physical-rom-section=$(($RPHYSADDR)) --rom-address=$(($ROMADDR)) --virtual-strings-section=$(($SVIRTADDR)) --physical-strings-section=$(($SPHYSADDR)) --www="$WEBS" --httpd="$FILE"

