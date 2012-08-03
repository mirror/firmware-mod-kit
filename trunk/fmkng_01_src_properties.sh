#!/bin/sh
[ ! -d 'src' ] && { echo 'This change is for FMK NG /trunk/trunk, please execute there'; return 2>/dev/null || exit; }


# create temporary file that will contain entries for svn:ignore
MYTEMPFILE=`mktemp`


###
###
MYDIR='src'
cat >"${MYTEMPFILE}" << __EOF
addpattern
asustrx
binwalk
config.log
config.status
Makefile
motorola-bin
splitter3
untrx
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/uncramfs-lzma'
cat >"${MYTEMPFILE}" << __EOF
uncramfs-lzma
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/uncramfs-lzma/lzma-rg/SRC/7zip/Compress/LZMA_C'
cat >"${MYTEMPFILE}" << __EOF
decode
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/cramfs-2.x'
cat >"${MYTEMPFILE}" << __EOF
mkcramfs
cramfsck
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/squashfs-3.0-lzma-damn-small-variant'
cat >"${MYTEMPFILE}" << __EOF
mksquashfs-lzma
unsquashfs-lzma
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/wrt_vx_imgtool'
cat >"${MYTEMPFILE}" << __EOF
wrt_vx_imgtool
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/binwalk-0.4.1/src'
cat >"${MYTEMPFILE}" << __EOF
config.log
config.h
Makefile
binwalk
config.status
file-5.07
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/crcalc'
cat >"${MYTEMPFILE}" << __EOF
crcalc
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/webcomp-tools'
cat >"${MYTEMPFILE}" << __EOF
webdecomp
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/squashfs-3.0'
cat >"${MYTEMPFILE}" << __EOF
mksquashfs
mksquashfs-lzma
unsquashfs
unsquashfs-lzma
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-3.3-lzma/squashfs3.3/squashfs-tools'
cat >"${MYTEMPFILE}" << __EOF
mksquashfs
unsquashfs
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-3.3-lzma/CPP/7zip/Compress/LZMA_Alone'
cat >"${MYTEMPFILE}" << __EOF
lzma
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-3.2-r2-lzma/squashfs3.2-r2/squashfs-tools'
cat >"${MYTEMPFILE}" << __EOF
mksquashfs
unsquashfs
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-3.2-r2-lzma/CPP/7zip/Compress/LZMA_Alone'
cat >"${MYTEMPFILE}" << __EOF
lzma
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-3.0-e2100'
cat >"${MYTEMPFILE}" << __EOF
mksquashfs
mksquashfs-lzma
unsquashfs
unsquashfs-lzma
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-4.0-realtek'
cat >"${MYTEMPFILE}" << __EOF
mksquashfs
unsquashfs
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-3.2-r2-wnr1000'
cat >"${MYTEMPFILE}" << __EOF
mksquashfs
unsquashfs
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-3.2-r2-hg612-lzma'
cat >"${MYTEMPFILE}" << __EOF
unsquashfs
mksquashfs
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-3.2-r2-hg612-lzma/squashfs3.2-r2/squashfs-tools'
cat >"${MYTEMPFILE}" << __EOF
mksquashfs
unsquashfs
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-3.2-r2-hg612-lzma/lzma443/C/7zip/Compress/LZMA_Alone'
cat >"${MYTEMPFILE}" << __EOF
lzma
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-3.2-r2-hg612-lzma/lzma443/C/7zip/Compress/LZMA_C'
cat >"${MYTEMPFILE}" << __EOF
lzmadec
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-2.0-nb4'
cat >"${MYTEMPFILE}" << __EOF
unsquashfs
mksquashfs
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-2.0-nb4/nb4-unsquashfs'
cat >"${MYTEMPFILE}" << __EOF
unsquashfs
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-2.0-nb4/nb4-mksquashfs'
cat >"${MYTEMPFILE}" << __EOF
mksquashfs
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-4.0-lzma'
cat >"${MYTEMPFILE}" << __EOF
mksquashfs-lzma
unsquashfs-lzma
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-3.3-grml-lzma/squashfs3.3/squashfs-tools'
cat >"${MYTEMPFILE}" << __EOF
mksquashfs
unsquashfs
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-3.3-grml-lzma/lzma/CPP/7zip/Compress/LZMA_Alone'
cat >"${MYTEMPFILE}" << __EOF
lzma
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-3.2-r2'
cat >"${MYTEMPFILE}" << __EOF
mksquashfs
unsquashfs
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/others/squashfs-3.3'
cat >"${MYTEMPFILE}" << __EOF
mksquashfs
unsquashfs
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/cramfsswap'
cat >"${MYTEMPFILE}" << __EOF
cramfsswap
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/squashfs-2.1-r2'
cat >"${MYTEMPFILE}" << __EOF
mksquashfs
mksquashfs-lzma
unsquashfs
unsquashfs-lzma
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


###
###
MYDIR='src/uncramfs'
cat >"${MYTEMPFILE}" << __EOF
uncramfs
__EOF
svn propset -F "${MYTEMPFILE}" svn:ignore ${MYDIR}


# clean up
rm -f "${MYTEMPFILE}"

MYTEMPFILE=
