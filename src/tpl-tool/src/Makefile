CC=gcc
CFLAGS=-O2
TARGET=tpl-tool

$(TARGET): md5.o
	$(CC) $(CFLAGS) $(LDFLAGS) $(TARGET).c *.o -o $(TARGET)

md5.o:
	$(CC) $(CFLAGS) $(LDFLAGS) md5.c -c

clean:
	rm -f *.o $(TARGET)
