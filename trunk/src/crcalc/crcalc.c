/*
 * Utility for calculating and patching checksums in various files.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include "crcalc.h"
#include "patch.h"

int main(int argc, char *argv[])
{
	int retval = EXIT_FAILURE, ok = 0;
	char *buf = NULL, *fname = NULL;
	size_t size = 0;

	/* Check usage */
	if(argc != 2 || argv[1][0] == '-')
	{
		fprintf(stderr, USAGE, argv[0]);
		goto end;
	}
	else
	{
		fname = argv[1];
	}

	buf = file_read(fname, &size);
	if(buf && size > MIN_FILE_SIZE)
	{
		switch(identify_header(buf))
		{
			case TRX:
				ok = patch_trx(buf, size);
				break;
			case UIMAGE:
				ok = patch_uimage(buf, size);
				break;
			default:
				fprintf(stderr, "Sorry, this file type is not supported.");
				break;
		}
	}
	else
	{
		fprintf(stderr, "ERROR: Cannot open file '%s', or file is too small.\n", fname);
	}

	if(ok)
	{
		if(!file_write(fname, buf, size))
		{
			fprintf(stderr, "Failed to save data to file '%s'\n", fname);
		}
		else
		{
			fprintf(stderr, "CRC updated successfully.\n");
			retval = EXIT_SUCCESS;
		}
	}
	else
	{
		fprintf(stderr, "CRC update failed.\n");
	}

end:
	if(buf) free(buf);
	return retval;
}

/* Reads in and returns the contents and size of a given file */
char *file_read(char *file, size_t *fsize)
{
        int fd = 0;
        struct stat _fstat = { 0 };
        char *buffer = NULL;

        if(stat(file, &_fstat) == -1)
        {
                perror(file);
                goto end;
        }

        if(_fstat.st_size == 0)
        {
                fprintf(stderr, "%s: zero size file\n", file);
                goto end;
        }

        fd = open(file,O_RDONLY);
        if(!fd)
        {
                perror(file);
                goto end;
        }

        buffer = malloc(_fstat.st_size);
        if(!buffer)
        {
                perror("malloc");
		goto end;
        }
        memset(buffer, 0 ,_fstat.st_size);

        if(read(fd, buffer, _fstat.st_size) != _fstat.st_size)
        {
                perror(file);
                if(buffer) free(buffer);
                buffer = NULL;
        }
        else
        {
                *fsize = _fstat.st_size;
        }

end:
        if(fd) close(fd);
        return buffer;
}

/* Write size bytes from buf to file fname */
int file_write(char *fname, char *buf, size_t size)
{
	FILE *fp = NULL;
	int retval = 0;

	fp = fopen(fname, "w");
	if(fp)
	{
		if(fwrite(buf, 1, size, fp) == size)
		{
			retval = 1;
		}
		
		fclose(fp);
	}
	else
	{
		perror("fopen");
	}

	return retval;
}

/* Identifies the header type used in the supplied file */
enum header_type identify_header(char *buf)
{
	enum header_type retval = UNKNOWN;
	uint32_t *sig = NULL;

	sig = (uint32_t *) buf;

	switch(*sig)
	{
		case TRX_MAGIC:
			retval = TRX;
			break;
		case UIMAGE_MAGIC:
			retval = UIMAGE;
			break;
		default:
			break;
	}

	return retval;
}

