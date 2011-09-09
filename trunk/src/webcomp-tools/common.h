#ifndef _COMMON_H_
#define _COMMON_H_

#include <stdint.h>

#define DEFAULT_OUTDIR 		"www"
#define DIRECTORY_TRAVERSAL 	".."
#define PATH_PREFIX 		"./"
#define EXE			"readelf --arch-specific %s 2>/dev/null | grep websRomPageIndex | awk '{print $4}'"
#define ELF_MAGIC		"\x7F\x45\x4C\x46"
#define NUM_PROGRAM_HEADERS	2

#pragma pack(1)

struct file_entry
{
	uint32_t name;
	uint32_t offset;
	uint32_t size;
};

struct entry_info
{
	char *name;
	struct file_entry *entry;
};

struct global
{
	int endianess;
	uint32_t index_address;
	uint32_t dv_address;
	uint32_t dv_offset;
	uint32_t tv_address;
	uint32_t tv_offset;
} globals;

void mkdir_p(char *dir);
char *make_path_safe(char *path);
int find_websRomPageIndex(char *httpd);
char *file_read(char *file, size_t *fsize);
void ntoh_struct(struct file_entry *entry);
void hton_struct(struct file_entry *entry);
int parse_elf_header(unsigned char *data, size_t size);
int file_write(char *file, unsigned char *data, size_t size);
struct entry_info *next_entry(unsigned char *data, uint32_t size);
uint32_t file_offset(uint32_t address, uint32_t virtual, uint32_t physical);
uint32_t virtual_address(uint32_t offset, uint32_t virtual, uint32_t physical);

#endif
