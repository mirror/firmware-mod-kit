#!/bin/sh
echo " Checking for updates ..."
mkdir update_check
cd update_check
wget --quiet --timeout=4 --tries=1 http://www.bitsum.com/files/firmware_mod_kit_version.txt
cd ..
if [ ! -f "update_check/firmware_mod_kit_version.txt" ]; then
	echo "  ! WARNING: Could not check for update. No connectivity or server down?"
	rm -rf update_check
	exit 1
fi
NEW_VERSION=`cat update_check/firmware_mod_kit_version.txt`
CUR_VERSION=`cat firmware_mod_kit_version.txt`
if [ $NEW_VERSION != $CUR_VERSION ]; then
	echo "  !!! There is a newer version available: $NEW_VERSION"
	echo "     You are currently using $CUR_VERSION"
else
	echo "  You have the latest version of this kit."
fi
rm -rf update_check
exit 0
