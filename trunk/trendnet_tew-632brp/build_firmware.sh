#/bin/sh
#
# Script written by Jeremy Collake (jeremy.collake@gmail.com)
# Bitsum Technologies http://www.bitsum.com
#
PARTS_PATH="./image_parts"
OUTPUT_PATH="./firmware_image_output"
OUTPUT_FIRMWARE_FILENAME="tew-632brp-fmk-firmware.bin"
echo "Building firmware for TEW-632BRP ..."
echo "NOTE: This script should be run as root!"
if [ ! -e "../src/squashfs-3.0/mksquashfs-lzma" ]; then	
	make -C "../src" 2>&1 > buildlog.log
	if [ ! -e "../src/squashfs-3.0/mksquashfs-lzma" ]; then
		echo "Error building mksquashfs-lzma! Check buildlog.log"
		exit 1
	fi	
fi
#
# unsquashfs the root filesystem
#
if [ ! -e "rootfs/" ]; then
	"../src/squashfs-3.0/unsquashfs-lzma" "image_parts/squashfs" -dest "./rootfs"
	#tar -xzvf rootfs.tar.gz
fi
mkdir -p "$OUTPUT_PATH"
rm -f "$PARTS_PATH/squashfs-3-lzma.img" "$OUTPUT_PATH/$OUTPUT_FIRMWARE_FILENAME"
../src/squashfs-3.0/mksquashfs-lzma "./rootfs/" "$PARTS_PATH/squashfs-3-lzma.img" -all-root -be -noappend
cp "$PARTS_PATH/vmlinuz" "$OUTPUT_PATH/$OUTPUT_FIRMWARE_FILENAME"
dd "if=$PARTS_PATH/squashfs-3-lzma.img" "of=$OUTPUT_PATH/$OUTPUT_FIRMWARE_FILENAME" bs=1K seek=1024
if [ -f "$PARTS_PATH/hwid.txt" ]; then
	cat "$PARTS_PATH/hwid.txt" >> "$OUTPUT_PATH/$OUTPUT_FIRMWARE_FILENAME"
else
	echo "ERROR: hwid.txt not found. This text is found at the very end of a firmware image."
fi
