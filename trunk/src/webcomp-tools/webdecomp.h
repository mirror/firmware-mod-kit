#ifndef _WEBDECOMP_H_
#define _WEBDECOMP_H_

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

void usage(char *progname);
int extract(char *httpd, char *www, char *outdir, uint32_t rom, uint32_t r_virtual, uint32_t r_physical, uint32_t s_virtual, uint32_t s_physical);

#endif
