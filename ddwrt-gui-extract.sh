#!/bin/bash

OUT="$1"
DIR="$2"

if [ "$DIR" == "" ]
then
	DIR="fmk/rootfs"
fi

if [ "$OUT" == "" ]
then
	OUT="www"
fi

eval $(cat shared-ng.inc)
HTTPD="$DIR/usr/sbin/httpd"
WWW="$DIR/etc/www"

echo -e "Firmware Mod Kit (ddwrt-gui-extract) $VERSION, (c)2011 Craig Heffner, Jeremy Collake\nhttp://www.bitsum.com\n"

if [ ! -d "$DIR" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]
then
	echo -e "Usage: $0 [output directory] [rootfs directory]\n"
	exit 1
fi

if [ ! -e "$HTTPD" ] || [ ! -e "$WWW" ]
then
	echo "Unable to locate httpd / www files in directory $DIR. Quitting..."
	exit 1
fi

# Extract!
./src/webcomp-tools/webdecomp --httpd="$HTTPD" --www="$WWW" --dir="$OUT" --extract

