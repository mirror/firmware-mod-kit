#/bin/sh
echo "Building firmware for TEW-632BRP ..."
if [ ! -e "../src/squashfs-3.0/mksquashfs-lzma" ]; then	
	make -C "../src" 2>&1 > buildlog.bat
	if [ ! -e "../src/squashfs-3.0/mksquashfs-lzma" ]; then
		echo "Error building mksquashfs-lzma! Check buildlog.bat"
		exit 1
	fi	
fi
if [ ! -e "rootfs/" ]; then
	tar -xzvf rootfs.tar.gz
fi
rm -f output/squashfs-3-lzma.img output/newfirmware.rom
../src/squashfs-3.0/mksquashfs-lzma ./rootfs/ output/squashfs-3-lzma.img -all-root -be -noappend
cp vmlinuz output/newfirmware.rom
dd if=output/squashfs-3-lzma.img of=output/newfirmware.rom bs=1K seek=1024
cat ./hwid.txt >> output/newfirmware.rom
