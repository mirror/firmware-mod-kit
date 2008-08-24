#/bin/sh
# (c)2008 Jeremy Collake
# Bitsum Technologies http://www.bitsum.com
# Released under GPL license
#
OUTPUT_FIRMWARE_FILENAME="tew-632brp-fmk-firmware.bin"
if [ $# = 2 ]; then
echo "Building firmware from directory $2 ..."
OUTPUT_PATH=$1
PARTS_PATH=$2
if [ $(id -u) != "0" ]; then
	echo "ERROR: This script should be run as root to create necessary devices!"
	exit 1
fi

if [ ! -e "../src/squashfs-3.0/mksquashfs-lzma" ]; then	
	make -C "../src" 2>&1 > buildlog.log
	if [ ! -e "../src/squashfs-3.0/mksquashfs-lzma" ]; then
		echo "Error building mksquashfs-lzma! Check buildlog.log"
		exit 1
	fi	
fi
if [ ! -e "$PARTS_PATH/rootfs_extracted/" ]; then
	echo "ERROR: rootfs must exist"
	exit 1
fi
mkdir -p "$OUTPUT_PATH"
rm -f "$PARTS_PATH/squashfs-3-lzma.img" "$OUTPUT_PATH/$OUTPUT_FIRMWARE_FILENAME"
../src/squashfs-3.0/mksquashfs-lzma "$PARTS_PATH/rootfs_extracted/" "$PARTS_PATH/squashfs-3-lzma.img" -all-root -be -noappend
cp "$PARTS_PATH/vmlinuz" "$OUTPUT_PATH/$OUTPUT_FIRMWARE_FILENAME"
dd "if=$PARTS_PATH/squashfs-3-lzma.img" "of=$OUTPUT_PATH/$OUTPUT_FIRMWARE_FILENAME" bs=1K seek=1024
if [ -f "$PARTS_PATH/hwid.txt" ]; then
	cat "$PARTS_PATH/hwid.txt" >> "$OUTPUT_PATH/$OUTPUT_FIRMWARE_FILENAME"
else
	echo "ERROR: hwid.txt not found. This text is found at the very end of a firmware image."
	exit 1
fi
echo "All done."
echo "Firmware image is at $OUTPUT_PATH/$OUTPUT_FIRMWARE_FILENAME"
else
	echo "ERROR: Invalid usage."
	echo "Usage: $0 firmware_image_output_dir/ working_dir/"
	exit 1
fi