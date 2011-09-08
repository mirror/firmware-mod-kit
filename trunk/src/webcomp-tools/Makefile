CC=gcc
CFLAGS=-Wall

all: webdecomp

webdecomp: common.o
	$(CC) $(CFLAGS) $(LDFLAGS) *.o webdecomp.c -o webdecomp

common.o:
	$(CC) $(CFLAGS) $(LDFLAGS) -c common.c

clean:
	rm -f webdecomp
	rm -f *.o
