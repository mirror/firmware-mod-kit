CC := gcc
CXX := g++
INCLUDEDIR = .
CFLAGS := -I$(INCLUDEDIR) -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -O2

all: squashfs3.0 asustrx addpattern untrx cramfs1.1 uncramfs

uncramfs:
	make -C uncramfs

cramfs1.1:
	make -C cramfs-1.1

squashfs3.0: 
	make -C squashfs-3.0

addpattern: addpattern.o
	$(CC) addpattern.o -lz -o $@

untrx: untrx.o
	$(CXX) untrx.o -lz -o $@

asustrx: asustrx.o
	$(CC) asustrx.o -lz -o $@

clean:
	rm -f *.o
	make -C squashfs-3.0 clean
	make -C cramfs-1.1 clean
	make -C uncramfs clean
