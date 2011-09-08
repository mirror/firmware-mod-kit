#ifndef _COMMON_H_
#define _COMMON_H_

#include <stdint.h>

#define DEFAULT_OUTDIR "./www"

struct file_entry
{
	uint32_t name;
	uint32_t offset;
	uint32_t size;
};

struct global
{
	int endianess;
} globals;

void mkdir_p(char *dir);
char *make_path_safe(char *path);
char *file_read(char *file, size_t *fsize);
uint32_t file_offset(uint32_t address, uint32_t virtual, uint32_t physical);

#endif
