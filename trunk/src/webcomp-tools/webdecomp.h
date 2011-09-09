#ifndef _WEBDECOMP_H_
#define _WEBDECOMP_H_

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#define MIN_ARGS 7
#define USAGE "\
webdecomp v.0.2, (c) 2011, Craig Heffner\n\
\n\
Extracts the Web UI pages from DD-WRT firmware.\n\
\n\
Usage: %s [OPTIONS]\n\
\n\
Required Options:\n\
\n\
\t-b, --httpd=<file>                    Path to the DD-WRT httpd binary (ex: usr/sbin/httpd)\n\
\t-w, --www=<file>                      Path to the DD-WRT www binary (ex: etc/www)\n\
\n\
Additional Options:\n\
\n\
\t-o, --out=<directory>                 Output directory [default: %s]\n\
\t-h, --help                            Show help\n\
\n\
The virtual address of the websRomPageIndex global can be found by running 'readelf --arch-specific <file>'.\n\
"

void usage(char *progname);
int extract(char *httpd, char *www, char *outdir);

#endif
