/*
 * Extracts the embedded Web GUI files from DD-WRT file systems.
 *
 * Craig Heffner
 * 07 September 2011
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>
#include <getopt.h>
#include "common.h"
#include "webdecomp.h"

int main(int argc, char *argv[])
{
	char *httpd = NULL, *www = NULL, *outdir = NULL;
	int rom_v_addr = 0, rom_p_addr = 0, romaddr = 0;
	int strings_v_addr = 0, strings_p_addr = 0;
	int retval = EXIT_FAILURE, long_opt_index = 0, ucount = 0, n = 0;
	char c = 0;

	char *short_options = "b:l:e:w:r:v:p:m:n:o:h";
	struct option long_options[] = {
		{ "httpd", required_argument, NULL, 'e' },
		{ "www", required_argument, NULL, 'w' },
		{ "virtual-rom-section", required_argument, NULL, 'v' },
		{ "physical-rom-section", required_argument, NULL, 'p' },
		{ "rom-address", required_argument, NULL, 'r' },
		{ "virtual-strings-section", required_argument, NULL, 'm' },
		{ "physical-strings-section", required_argument, NULL, 'n' },
		{ "out", required_argument, NULL, 'o' },
		{ "big-endian", no_argument, NULL, 'b' },
		{ "little-endian", no_argument, NULL, 'l' },
		{ "help", no_argument, NULL, 'h' },
		{ 0, 0, 0, 0 }
	};
	
	while((c = getopt_long(argc, argv, short_options, long_options, &long_opt_index)) != -1)
	{
		switch(c)
		{
			case 'b':
				globals.endianess = BIG_ENDIAN;
				break;
			case 'l':
				globals.endianess = LITTLE_ENDIAN;
				break;
			case 'e':
				httpd = strdup(optarg);
				ucount++;
				break;
			case 'w':
				www = strdup(optarg);
				ucount++;
				break;
			case 'r':
				romaddr = atoi(optarg);
				ucount++;
				break;
			case 'v':
				rom_v_addr = atoi(optarg);
				ucount++;
				break;
			case 'p':
				rom_p_addr = atoi(optarg);
				ucount++;
				break;
			case 'm':
				strings_v_addr = atoi(optarg);
				ucount++;
				break;
			case 'n':
				strings_p_addr = atoi(optarg);
				ucount++;
				break;
			case 'o':
				outdir = strdup(optarg);
				break;
			default:
				usage(argv[0]);
				goto end;
			
		}
	}

	/* Verify that all required options were specified  */
	if(ucount != MIN_ARGS)
	{
		usage(argv[0]);
		goto end;
	}

	/* If no output directory was specified, use the default (www) */
	if(!outdir)
	{
		outdir = strdup(DEFAULT_OUTDIR);
	}

	/* Extract! */
	n = extract(httpd, www, outdir, romaddr, rom_v_addr, rom_p_addr, strings_v_addr, strings_p_addr);

	if(n > 0)
	{
		printf("\nExtracted %d files to %s.\n\n", n, outdir);
		retval = EXIT_SUCCESS;
	}
	else
	{
		fprintf(stderr, "Extraction failed!\n");
	}

end:
	if(httpd) free(httpd);
	if(www) free(www);
	if(outdir) free(outdir);
	return retval;
}

/* Extract embedded file contents from binary file(s) */
int extract(char *httpd, char *www, char *outdir, uint32_t rom, uint32_t r_virtual, uint32_t r_physical, uint32_t s_virtual, uint32_t s_physical)
{
	int n = 0;
	uint32_t rom_offset = 0, str_offset = 0, offset = 0;
	size_t hsize = 0, wsize = 0;
	struct file_entry *entry = NULL;
	unsigned char *hdata = NULL, *wdata = NULL;
	char *dir_tmp = NULL, *path = NULL;

	/* Calculate the physical offset of the websRomIndex array */
	rom_offset = file_offset(rom, r_virtual, r_physical);

	/* Read in the httpd and www files */
	hdata = (unsigned char *) file_read(httpd, &hsize);
	wdata = (unsigned char *) file_read(www, &wsize);

	/* Create the output directory, if it doesn't already exist */
	mkdir_p(outdir);

	/* Change directories to the output directory */
        if(chdir(outdir) == -1)
        {
                perror(outdir);
        }
	else
	{
		/* Make sure all our data and calculations are OK */
		if(hdata && wdata && (hsize > rom_offset))
		{
			/* Loop through the structure array until we hit the end of the file, or we break due to a NULL entry name */
			while((offset = rom_offset + (sizeof(struct file_entry) * n)) < hsize)
			{
				entry = (struct file_entry *) (hdata + offset);

				/* A NULL entry name signifies the end of the array */
				if(entry->name == 0)
				{
					break;
				}
				else
				{
					/* Get the physical offset of the file name string */
					str_offset = file_offset(entry->name, s_virtual, s_physical);
				
					/* Sanity check */
					if(str_offset >= hsize)
					{
						break;
					}
					else
					{
						/* Point entry->name at the actual string */
						entry->name = (uint32_t) (hdata + str_offset);
					}
				}

				/* Make sure the full file path is safe (i.e., it won't overwrite something critical on the host system) */
				path = make_path_safe((char *) entry->name);
				if(path)
				{
					/* Display the file name */
					printf("%s\n", (char *) entry->name);
					
					/* dirname() clobbers the string you pass it, so make a temporary one */
					dir_tmp = strdup(path);
					mkdir_p(dirname(dir_tmp));
					free(dir_tmp);

					/* Write the data to disk */
					if(file_write(path, (wdata + entry->offset), entry->size))
					{
						n++;
					}

					free(path);
				}
				else
				{
					fprintf(stderr, "File path '%s' is not safe! Skipping...\n", (char *) entry->name);
				}
			}
		}
	}

	if(hdata) free(hdata);
	if(wdata) free(wdata);
	return n;
}

void usage(char *progname)
{
	fprintf(stderr, "\n");
	fprintf(stderr, USAGE, progname, DEFAULT_OUTDIR);
	fprintf(stderr, "\n");

	return;
}
