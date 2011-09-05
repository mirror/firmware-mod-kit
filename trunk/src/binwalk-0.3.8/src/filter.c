#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "filter.h"

/* Appends a new filter to the filters array */
void add_filter(struct magic_filter *filters[], int *filter_count, enum filter_type_t type, char* filter)
{
        if(*filter_count < MAX_FILTERS)
        {
                filters[*filter_count] = malloc(sizeof(struct magic_filter));
                if(filters[*filter_count] != NULL)
                {
                        memset(filters[*filter_count], 0, sizeof(struct magic_filter));

                        filters[*filter_count]->type = type;
                        filters[*filter_count]->filter = strdup(filter);
                        *filter_count = *filter_count+1;
                }
                else
                {
                        perror("Malloc failure");
                }
        }

        return;
}

/* Check to see if the description matches any of the include / exclude filters */
enum filter_result_t filter_check(struct magic_filter *filters[], int filter_count, char *description)
{
	int i = 0; 
	enum filter_result_t found = RESULT_NOT_FOUND;

	/* If include filters have been specified, then ONLY those descriptions that match the include filters
	 * should be used. Loop through to see if there are any include filters; if so, make sure this desciption
	 * matches one of the include filters.
	 */
	for(i=0; i<filter_count; i++)
	{
		if(filters[i]->type == FILTER_INCLUDE || filters[i]->type == FILTER_ADD)
		{
			/* If and explicit include filter was specified, then default to RESULT_EXCLUDE unless a match is found */
			if(filters[i]->type == FILTER_INCLUDE)
			{
				found = RESULT_EXCLUDE;
			}

			if(string_contains(description, filters[i]->filter))
			{
				found = RESULT_INCLUDE;
				break;
			}
		}
	}

	
	/* Check to see if description matches any exclude filters */
	for(i=0; i<filter_count; i++)
	{
		if(filters[i]->type == FILTER_EXCLUDE)
		{
			if(string_contains(description, filters[i]->filter))
			{
				found = RESULT_EXCLUDE;
				break;
			}
		}
	}

	return found;
}

/* Performs a case-insensitive string search */
int string_contains(char *haystack, char *needle)
{
	char *my_haystack = NULL, *my_needle = NULL;
	int retval = 0, i = 0;
	size_t haystack_size = 0, needle_size = 0;

	/* Duplicate the input strings */
	my_haystack = strdup(haystack);
	my_needle = strdup(needle);

	if(!my_haystack || !my_needle)
	{
		perror("strdup");
	}
	else
	{
		haystack_size = strlen(my_haystack);
		needle_size = strlen(my_needle);

		/* Convert needle to all upper case */
		for(i=0; i<needle_size; i++)
		{
			my_needle[i] = toupper(my_needle[i]);
		}

		/* Convert haystack to all upper case */
		for(i=0; i<haystack_size; i++)
		{
			my_haystack[i] = toupper(my_haystack[i]);
		}

		/* Search for needle in haystack */
		if(strstr(my_haystack, my_needle) != NULL)
		{
			retval = 1;
		}
	}

	if(my_haystack) free(my_haystack);
	if(my_needle) free(my_needle);
	return retval;
}
