dnl Many thanks to Anthony Basile for the initial configure script and Makefile

AC_PREREQ([2.65])
AC_INIT([binwalk],[0.3.9],[http://code.google.com/p/binwalk/issues/list])
AC_CONFIG_SRCDIR([md5.c])

AC_PROG_CC
AC_LANG(C)

FILE="file-5.07"
CFLAGS="-Wall -I./$FILE/src $CFLAGS"
LDFLAGS="-lz $LDFLAGS"

AC_ARG_ENABLE([static],    [  --enable-static         perform static build ], [STATIC=y], [STATIC=n])
AC_ARG_ENABLE([updates],   [  --disable-updates       disable update features that rely on libcurl ], [CURL=n], [CURL=y])

if test $CURL = y
then
	AC_CHECK_LIB([curl],[curl_easy_init],[],[echo "error: missing libcurl library" && exit],[])
	AC_CHECK_HEADERS([curl/curl.h],[],[echo "error: missing curl header files" && exit])

	LDFLAGS="-lcurl $LDFLAGS"
fi

AC_CHECK_HEADERS([arpa/inet.h fcntl.h stdlib.h string.h unistd.h],[],[echo "error: missing necessary header file" && exit])

AC_TYPE_SIZE_T

AC_FUNC_MALLOC

AC_CHECK_FUNCS([memset strdup strstr strtol],[],AC_MSG_ERROR(["Missing necessary function"]))

dnl curl static libs only required if we're doing a static build
if test $STATIC = y
then
	CLIBS=$(curl-config --static-libs)
	LDFLAGS="-static $CLIBS $LDFLAGS"
fi

dnl extract and run file utility configure script
tar -zxvf $FILE.tar.gz && cd $FILE && ./configure && cd -

if test $CURL = n
then
	CFLAGS="-DNOCURL $CFLAGS"
fi

cp confdefs.h config.h

AC_SUBST(FILE, $FILE)
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
