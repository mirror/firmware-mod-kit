#!/bin/sh
SHARED_VERSION='0.43 beta'
#
# Title: shared.inc
# Author: Jeremy Collake <jeremy@bitsum.com>
#
# Shared functions
#
#
#

#################################################################
WarningPrompt ()
{
	read -p " [ Press any key to contrinue, or abort now with break signal (CTRL-C) ]"
}
#################################################################
PlatformIdentify ()
{
SYSNAME=`uname`
	if [ "$SYSNAME" = "Linux" ]; then
		echo "  LINUX system detected. Compatibility ok."	
	elif [ `expr "$SYSNAME" : "Darwin"` = 6 ]; then
		echo "  OS X system detected. **BETA TESTING**"
		echo "  This platform is not well tested."
		WarningPrompt				
	elif [ `expr "$SYSNAME" : "CYGWIN"` = 6 ]; then
		echo "  CYGWIN system detected. **BETA TESTING** Built images may have problems."
		echo "  This platform is not well tested."
		WarningPrompt			
	else
		echo "  Unknown system detected. Compatibility state is unknown."
		WarningPrompt
	fi
}
#################################################################
TestFileSystemExit ()
{
INPUT_FILE=$1
WORKING_DIR=$2
	echo "  Testing file system of $WORKING_DIR ..."
	mkdir -p "$WORKING_DIR" >> /dev/null 2>&1
	rm "$WORKING_DIR/test12345612.tmp" >> /dev/null 2>&1
	echo test > "$WORKING_DIR/test12345612.tmp"
	if [ -e "$WORKING_DIR/teST12345612.tmp" ]; then
		echo "  WARNING: File system $WORKING_DIR is not case sensitive."		
		echo "      For some firmwares this can cause troubles in the"
		echo "      built images that result in runtime errata or"
		echo "      even refuse to boot."
		if [ $EXIT_ON_FS_PROBLEM = "1" ]; then
			rm "$WORKING_DIR/test12345612.tmp" >> /dev/null 2>&1
			exit 2
		else
			WarningPrompt				
		fi	
	fi	
	if [ ! -e "$WORKING_DIR/test12345612.tmp" ]; then
		echo "  ERROR: File system $WORKING_DIR is not writable."
		rm "$WORKING_DIR/test12345612.tmp" >> /dev/null 2>&1
		exit 3
	fi
	rm "$WORKING_DIR/test12345612.tmp" >> /dev/null 2>&1
}
#################################################################
# LinkToolsBinraries (srcfolder, destfolder)
LinkToolsBinaries ()
{
	ln -s -f $1/asustrx $2/asustrx
	ln -s -f $1/untrx $2/untrx
	ln -s -f $1/mksquashfs $2/mksquashfs
	ln -s -f $1/mksquashfs-lzma $2/mksquashfs-lzma	
	ln -s -f $1/unsquashfs $2/unsquashfs
	ln -s -f $1/unsquashfs-lzma $2/unsquashfs-lzma
	ln -s -f $1/addpattern $2/addpattern	
}



#################################################################

CleanCWD ()
{
make clean >> cleanup.log 2>&1
rm -f *.log
rm -f *.o
rm -f asustrx
rm -f trx
rm -f untrx
rm -f addpattern
rm -f mksquashfs
rm -f mksquashfs-lzma
rm -f unsquashfs
rm -f unsquashfs-lzma
# cygwin
rm -f asustrx.exe
rm -f trx.exe
rm -f untrx.edxe
rm -f addpattern.exe
rm -f mksquashfs.exe
rm -f mksquashfs-lzma.exe
rm -f unsquashfs.exe
rm -f unsquashfs-lzma.exe
# old name for untrx, deprecated
rm -f extfirmware*
# trx replaced with asustrx
rm -f trx.c
}
Cleanup ()
{
CleanCWD
cd src
CleanCWD
cd ..
}

#################################################################
# BuildTools ( LOG_FILE )
#
#
BuildTools ()
{
	local LOG_FILE="$1"
	#################################################################
	echo "  Building tools ..."
	make -C src > $LOG_FILE 2>&1
	if [ -e "src/untrx.o" ] && [ -e "src/asustrx.o" ] && [ -e "src/mksquashfs-lzma" ] && [ -e "src/unsquashfs-lzma" ]; 		then
		echo "  Build seems successful."
	else
		echo "  ERROR - Build did not succeed. Check build.log, you are probably"
		echo "          missing one or more necessary pre-requisites. See docs for"
		echo "          a list of pre-requsites."
		if [ -e "src/untrx" ]; then
			echo "  CONTINUING anyway, attempting to use pre-built binaries (x32 linux)"	
		else
			exit 1
		fi
	fi
	#################################################################
	local UNAME2=`uname`
	if [ `expr "$UNAME2" : "CYGWIN"` = 6 ]; then
		ln -s -f "src/asustrx.exe" "src/asustrx" >> $LOG_FILE 2>&1
		ln -s -f "src/untrx.exe" "src/untrx" >> $LOG_FILE 2>&1
		ln -s -f "src/addpattern.exe" "src/addpattern" >> $LOG_FILE 2>&1
		ln -s -f "src/mksquashfs-lzma.exe" "src/mksquashfs-lzma"  >> $LOG_FILE 2>&1
		ln -s -f "src/unsquashfs-lzma.exe" "src/unsquashfs-lzma"  >> $LOG_FILE 2>&1
		ln -s -f "src/mksquashfs.exe" "src/mksquashfs"  >> $LOG_FILE 2>&1
		ln -s -f "src/unsquashfs.exe" "src/unsquashfs"  >> $LOG_FILE 2>&1
	fi
	#################################################################
	# cygwin: this can not be called before above block (no *. bins exist)
	LinkToolsBinaries "src" "."
}
