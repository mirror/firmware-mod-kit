#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include "common.h"

/* Given the physical and virtual section loading addresses, convert a virtual address to a physical file offset */
uint32_t file_offset(uint32_t address, uint32_t virtual, uint32_t physical)
{
        uint32_t offset = 0;

        offset = (address-virtual+physical);

        if(globals.endianess == BIG_ENDIAN)
        {
                offset = (uint32_t) ntohl(offset);
        }

        return offset;
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

/* Writes data to the specified file */
int file_write(char *file, unsigned char *data, size_t size)
{
	FILE *fp = NULL;
	int retval = 0;

	fp = fopen(file, "wb");
	if(fp)
	{
		if(fwrite(data, 1, size, fp) != size)
		{
			perror("fwrite");
		}
		else
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

/* Recursive mkdir (same as mkdir -p) */
void mkdir_p(char *dir) 
{
        char tmp[FILENAME_MAX] = { 0 };
        char *p = NULL;
        size_t len = 0;
 
        snprintf(tmp, sizeof(tmp),"%s",dir);
        len = strlen(tmp);

        if(tmp[len - 1] == '/')
	{
		tmp[len - 1] = 0;
	}

        for(p = tmp + 1; *p; p++)
	{
                if(*p == '/') 
		{
                        *p = 0;
                        mkdir(tmp, S_IRWXU);
                        *p = '/';
                }
	}

        mkdir(tmp, S_IRWXU);

	return;
}

/* Sanitize the specified file path */
char *make_path_safe(char *path)
{
	int size = 0;
	char *safe = NULL;

	/* Make sure the specified path is valid, and that there are no traversal issues */
	if(path != NULL && strstr(path, DIRECTORY_TRAVERSAL) == NULL)
	{
		/* Append a './' to the beginning of the file path */
		size = strlen(path) + strlen(PATH_PREFIX) + 1;
		safe = malloc(size);
		if(safe)
		{
			memset(safe, 0, size);
			memcpy(safe, PATH_PREFIX, 2);
			strcat(safe, path);
		}
	}

	return safe;
}
