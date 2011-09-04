#ifndef _CRCALC_H_
#define _CRCALC_H_

#include <stdint.h>

#define MIN_FILE_SIZE 4

#define USAGE "\n\
crcalc v0.1 - (c) 2011, Craig Heffner\n\
Re-calculates firmware header checksusms for TRX and uImage firmware headers.\n\
\n\
Usage: %s <firmware image>\n\
\n"

enum header_type
{
	UNKNOWN,
	TRX,
	UIMAGE
};

char *file_read(char *file, size_t *fsize);
int file_write(char *fname, char *buf, size_t size);
enum header_type identify_header(char *buf);

#endif
