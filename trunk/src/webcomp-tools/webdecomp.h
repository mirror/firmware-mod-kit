#ifndef _WEBDECOMP_H_
#define _WEBDECOMP_H_

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#define MIN_ARGS 7
#define USAGE "\
webdecomp v.0.1, (c) 2011, Craig Heffner\n\
\n\
Extracts the Web UI pages from DD-WRT firmware.\n\
\n\
Usage: %s [OPTIONS]\n\
\n\
Required Options:\n\
\n\
\t-e, --httpd=<file>                    Path to the DD-WRT httpd binary (ex: usr/sbin/httpd)\n\
\t-w, --www=<file>                      Path to the DD-WRT www binary (ex: etc/www)\n\
\t-v, --virtual-rom-section=<int>       Virtual address of the ELF section that contains the websRomPageIndex global variable\n\
\t-p, --physical-rom-section=<int>      Physical address of the ELF section that contains the websRomPageIndex global variable\n\
\t-r, --rom-address=<int>               Address of the websRomPageIndex global variable\n\
\t-m, --virtual-strings-section=<int>   Virtual address of the ELF section that contains the Web page URL strings\n\
\t-n, --physical-strings-section=<int>  Physical address of the ELF section that contains the Web page URL strings\n\
\n\
Additional Options:\n\
\n\
\t-o, --out=<directory>                 Output directory [default: %s]\n\
\t-b, --big-endian                      The httpd binary is from a big-endian system [default: false]\n\
\t-l, --little-endian                   The httpd binary is from a little-endian system [default: true]\n\
\t-h, --help                            Show help\n\
\n\
All virtual/physical address information can be found using the readelf utility (standard in all Linux distros).\n\
See the README file for detailed examples.\n\
"

void usage(char *progname);
int extract(char *httpd, char *www, char *outdir, uint32_t rom, uint32_t r_virtual, uint32_t r_physical, uint32_t s_virtual, uint32_t s_physical);

#endif
