#include <stdio.h>
#include <curl/curl.h>
#include <curl/easy.h>
#include "update.h"

size_t write_data(void *ptr, size_t size, size_t nmemb, FILE *fp)
{
	size_t written = 0;

	written = fwrite(ptr, size, nmemb, fp);

	return written;
}

int update_magic_file(char *url, char *outfile) 
{
	CURLcode res;
	CURL *curl = NULL;
	FILE *fp = NULL;
	int retval = 0;
    
	curl = curl_easy_init();
	if(curl) 
	{
        	fp = fopen(outfile,"wb");
		if(fp)
		{
        		curl_easy_setopt(curl, CURLOPT_URL, url);
        		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
        		curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
        		res = curl_easy_perform(curl);
        		curl_easy_cleanup(curl);
        		fclose(fp);
			retval = 1;
		} 
		else 
		{
			perror(outfile);
		}
    	}

    	return retval;
}
