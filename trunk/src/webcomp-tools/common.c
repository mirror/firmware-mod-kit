#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <elf.h>
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

/* Returns the next web file entry */
struct file_entry *next_entry(unsigned char *data, uint32_t size)
{
	static int n;
	uint32_t offset = 0, rom_offset = 0, str_offset = 0;
	struct file_entry *entry = NULL;

	/* Calculate the physical offset of the websRomIndex array */
        rom_offset = file_offset(globals.index_address, globals.dv_address, globals.dv_offset);

	/* Calculate the offset into the array for the next entry */
	offset = rom_offset + (sizeof(struct file_entry) * n);

	if(offset < (size + sizeof(struct file_entry)))
	{
		entry = (struct file_entry *) (data + offset);

		/* A NULL entry name signifies the end of the array */
		if(entry->name == 0)
		{
			entry = NULL;
		}
		else
		{
			/* Get the physical offset of the file name string */
			str_offset = file_offset(entry->name, globals.tv_address, globals.tv_offset);

			/* Sanity check */
			if(str_offset >= size)
			{
				entry = NULL;
			}
			else
			{
				/* Point entry->name at the actual string */
				entry->name = (uint32_t) (data + str_offset);
				n++;
			}
		}
	}

	return entry;
}

/* Get the virtual addresses and physical offsets of the program headers in the ELF file */
int parse_elf_header(unsigned char *data, size_t size)
{
	int i = 0, n = 0, retval = 0;
	Elf32_Ehdr *header = NULL;
	Elf32_Phdr *program = NULL;

	if(data && size > sizeof(Elf32_Ehdr))
	{
		header = (Elf32_Ehdr *) data;

		if(strncmp((char *) &header->e_ident, ELF_MAGIC, 4) == 0)
		{
			if(header->e_ident[EI_DATA] == ELFDATA2MSB)
			{
				globals.endianess = BIG_ENDIAN;
			}
			else
			{
				globals.endianess = LITTLE_ENDIAN;
			}

			/* Loop through program headers looking for TEXT and DATA headers */
			for(i=0; i<header->e_phnum; i++)
			{
				program = (Elf32_Phdr *) (data + header->e_phoff + (sizeof(Elf32_Phdr) * i));
	
				if(program->p_type == PT_LOAD)
				{
					/* TEXT */
					if((program->p_flags | PF_X) == program->p_flags)
					{
						globals.tv_address = program->p_vaddr;
						globals.tv_offset = program->p_offset;
						n++;
					}
					/* DATA */
					else if((program->p_flags | PF_R | PF_W) == program->p_flags)
					{
						globals.dv_address = program->p_vaddr;
						globals.dv_offset = program->p_offset;
						n++;
					}
				}
			}
		}
	}

	/* Return true if both program headers were identified */
	if(n == NUM_PROGRAM_HEADERS)
	{
		retval = 1;
	}

	return retval;
}

/* Get the virtual offset to the websRomPageIndex variable */
int find_websRomPageIndex(char *httpd)
{
	char *cmd = 0;
	char output[256] = { 0 };
	FILE *phandle = NULL;
	int size = 0, retval = 0;

	size = strlen(EXE) + strlen(httpd) + 1;

	cmd = malloc(size);
	if(cmd)
	{
		memset(cmd, 0, size);
		snprintf(cmd, size, EXE, httpd);

		/* This feels so wrong, but it works... */
		phandle = popen(cmd, "r");
		if(phandle)
		{
			if(fread((char *) &output, 1, sizeof(output), phandle) > 0)
			{
				globals.index_address = strtol((char *) &output, NULL, 16);
				retval = 1;
			}
			else
			{
				perror("popen fread");
			}

			pclose(phandle);
		}
		else
		{
			perror(cmd);
		}			
	}

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
