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
	int retval = EXIT_FAILURE, long_opt_index = 0, ucount = 0, n = 0;
	char c = 0;

	char *short_options = "b:w:o:h";
	struct option long_options[] = {
		{ "httpd", required_argument, NULL, 'b' },
		{ "www", required_argument, NULL, 'w' },
		{ "out", required_argument, NULL, 'o' },
		{ "help", no_argument, NULL, 'h' },
		{ 0, 0, 0, 0 }
	};
	
	while((c = getopt_long(argc, argv, short_options, long_options, &long_opt_index)) != -1)
	{
		switch(c)
		{
			case 'b':
				httpd = strdup(optarg);
				ucount++;
				break;
			case 'w':
				www = strdup(optarg);
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
	if(ucount != 2)
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
	n = extract(httpd, www, outdir);

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
int extract(char *httpd, char *www, char *outdir)
{
	int n = 0;
	size_t hsize = 0, wsize = 0;
	struct file_entry *entry = NULL;
	unsigned char *hdata = NULL, *wdata = NULL;
	char *dir_tmp = NULL, *path = NULL;

	/* Read in the httpd and www files */
	hdata = (unsigned char *) file_read(httpd, &hsize);
	wdata = (unsigned char *) file_read(www, &wsize);
	
	if(hdata != NULL && wdata != NULL && find_websRomPageIndex(httpd) && parse_elf_header(hdata, hsize))
	{
		/* Create the output directory, if it doesn't already exist */
		mkdir_p(outdir);

		/* Change directories to the output directory */
        	if(chdir(outdir) == -1)
        	{
                	perror(outdir);
        	}
		else 
		{
			/* Get the next entry until we get a blank entry */
			while((entry = next_entry(hdata, hsize)) != NULL)
			{
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
					if(!file_write(path, (wdata + entry->offset), entry->size))
					{
						fprintf(stderr, "ERROR: Failed to extract file '%s'\n", (char *) entry->name);
					}
					else
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
	else
	{
		printf("Failed to parse ELF header!\n");
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
