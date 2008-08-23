#/bin/sh
echo "Building firmware for TEW-632BRP ..."
if [ ! -e "rootfs/" ]; then
	tar -xzvf rootfs.tar.gz
fi
rm -f output/squashfs-3-lzma.img output/newfirmware.rom
./mksquashfs_ap71 ./rootfs/ output/squashfs-3-lzma.img -all-root -be -noappend
cp vmlinuz output/newfirmware.rom
dd if=output/squashfs-3-lzma.img of=output/newfirmware.rom bs=1K seek=1024
cat ./hwid.txt >> output/newfirmware.rom
