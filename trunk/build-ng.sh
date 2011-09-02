#!/bin/bash

DIR="$1"

if [ "$DIR" == "" ]
then
	DIR="fmk"
fi

eval $(cat shared-ng.inc)
eval $(cat $CONFLOG)

FSOUT="$DIR/newfs.$FS_TYPE"
FWOUT="$DIR/fw.img"

echo "Building new $FS_TYPE file system..."

case $FS_TYPE in
	"squashfs")
		$MKFS $ROOTFS $FSOUT $ENDIANESS -all-root
		;;
esac

if [ ! -e $FSOUT ]
then
	echo "Unsupported file system ($FS_TYPE), or failed to create new file system. Quitting..."
	exit 1
fi

cp $HEADER_IMAGE $FWOUT

((FILLER_SIZE=$FS_OFFSET-$HEADER_IMAGE_OFFSET-$HEADER_IMAGE_SIZE))
perl -e "print \"\xFF\"x$FILLER_SIZE" >> $FWOUT

cat $FSOUT >> $FWOUT

CUR_SIZE=$(ls -l $FWOUT | awk '{print $5}')
((FILLER_SIZE=$FOOTER_OFFSET-$CUR_SIZE))
echo "$FOOTER_OFFSET-$CUR_SIZE=$FILLER_SIZE"
perl -e "print \"\xFF\"x$FILLER_SIZE" >> $FWOUT

if [ "$FOOTER_SIZE" -gt "0" ]
then
	cat $FOOTER_IMAGE >> $FWOUT
fi

if [ "$HEADER_IMAGE_SIZE" -gt "$FS_OFFSET" ]
then
	case $HEADER_TYPE in
		"trx")
			mv $FWOUT $FWOUT.tmp && ./src/asustrx -o $FWOUT $FWOUT.tmp && rm -f $FWOUT.tmp
			;;
	esac
fi

echo "Finished! New firmware image has been saved to: $FWOUT"

