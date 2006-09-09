CC := gcc
CXX := g++
INCLUDEDIR = .
CFLAGS := -I$(INCLUDEDIR) -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -O2

all: asustrx addpattern untrx motorola-bin
	make -C ./uncramfs/
	make -C ./cramfs-2.x/
	make -C ./squashfs-3.0/
	make -C ./wrt_vx_imgtool/

addpattern: addpattern.o
	$(CC) addpattern.o -lz -o $@

untrx: untrx.o
	$(CXX) untrx.o -lz -o $@

asustrx: asustrx.o
	$(CC) asustrx.o -lz -o $@

motorola-bin: motorola-bin.o
	$(CC) motorola-bin.o -o $@

clean:
	rm -f *.o
	rm motorola-bin
	rm untrx
	rm asustrx
	rm addpattern
	make -C squashfs-3.0 clean
	make -C cramfs-2.x clean
	make -C uncramfs clean
	make -C wrt_vx_imgtool clean
