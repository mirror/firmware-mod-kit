CC=gcc
CFLAGS=-Wall
TARGET=crcalc

$(TARGET): patch.o
	$(CC) $(CFLAGS) $(LDFLAGS) $(TARGET).c *.o -o $(TARGET)

patch.o: crc.o
	$(CC) $(CFLAGS) $(LDFLAGS) patch.c -c

crc.o:
	$(CC) $(CFLAGS) $(LDFLAGS) crc.c -c

clean:
	rm -f *.o $(TARGET)
