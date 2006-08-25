/* untrx
 * Copyright (C) 2006  Jeremy Collake  <jeremy@bitsum.com>
 *
 *	version: 0.44 beta		
 *	Quick and dirty tool to find and extract parts of a cybertan style firmware		
 *	I whipped this out quickly. Didn't spend much/any time on polishing.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/types.h>

#ifndef __DARWIN_UNIX03
#include <endian.h>
#include <byteswap.h>
#else
#include <ppc/endian.h>
#endif
#include <sys/types.h>

#include "untrx.h"

/*************************************************************************
* IdentifySegment
*
* identifies segments (i.e. squashfs, cramfs) and their version numbers
*
**************************************************************************/
SEGMENT_TYPE IdentifySegment(unsigned char *pData, unsigned long nLength)
{
	squashfs_super_block *sqblock=(squashfs_super_block *)pData;
	if(sqblock->s_magic==SQUASHFS_MAGIC 
		|| sqblock->s_magic==SQUASHFS_MAGIC_SWAP
		|| sqblock->s_magic==SQUASHFS_MAGIC_ALT
		|| sqblock->s_magic==SQUASHFS_MAGIC_ALT_SWAP)
	{		
		switch(sqblock->s_major)
		{
			case 3:
				switch (sqblock->s_minor)
				{
					case 0:						
						return SEGMENT_TYPE_SQUASHFS_3_0;
					case 1:						
						return SEGMENT_TYPE_SQUASHFS_3_1;					
					default:
						return SEGMENT_TYPE_SQUASHFS_OTHER;						
				}
			case 2:
				switch (sqblock->s_minor)
				{
					case 0:
						return SEGMENT_TYPE_SQUASHFS_2_0;
					case 1:
						return SEGMENT_TYPE_SQUASHFS_2_1;
					default:
						return SEGMENT_TYPE_SQUASHFS_OTHER;						
				}
			default:
				return SEGMENT_TYPE_SQUASHFS_OTHER;				
		}
	}	
	
	return SEGMENT_TYPE_UNTYPED;
}

void ShowUsage()
{			
	fprintf(stderr, " ERROR: Invalid usage.\n"		
		" USAGE: untrx binfile outfolder\n");	
	exit(9);
}

/* main */
int main(int argc, char **argv)
{
	printf(" untrx v0.44 beta - (c)2006 Jeremy Collake\n");
	
	if(argc<3)
	{
		ShowUsage();
	}
	
	printf(" Opening %s\n", argv[1]);
	FILE *fIn=fopen(argv[1],"rb");
	if(!fIn)
	{
		fprintf(stderr, " ERROR opening %s\n", argv[1]);
		exit(1);
	}
	
	char *pszOutFolder=(char *)malloc(strlen(argv[2])+sizeof(char));
	strcpy(pszOutFolder,argv[2]);
	if(pszOutFolder[strlen(pszOutFolder)-1]=='/')
	{
		pszOutFolder[strlen(pszOutFolder)-1]=0;		
	}	
	
	fseek(fIn,0,SEEK_END);
	size_t nFilesize=ftell(fIn);
	fseek(fIn,0,SEEK_SET);	
	unsigned char *pData=(unsigned char *)malloc(nFilesize);	
	if(fread(pData,1,nFilesize,fIn)!=nFilesize)
	{
		fprintf(stderr," ERROR reading %s\n", argv[1]);		
		fclose(fIn);	
		free(pData);
		free(pszOutFolder);	
		exit(1);
	}	
	fclose(fIn);	
	printf(" read %u bytes\n", nFilesize);
	
	// uf U2ND header present, skip past it (pData is preserved above)
	trx_header *trx=(trx_header *)pData;
	if(READ32_LE(trx->magic)!=TRX_MAGIC)
	{
		pData+=U2ND_HEADER_SIZE;	
		trx=(trx_header *)pData;	
		if(READ32_LE(trx->magic)!=TRX_MAGIC)
		{
			fprintf(stderr," ERROR trx header not found\n");
			free(pData);
			free(pszOutFolder);	
			exit(2);			
		}
	}
	
	// allocate filename buffer
	char *pszTemp=(char *)malloc(strlen(pszOutFolder)+128);			
	
	/* Extract the segments */
	for(int nI=0;nI<3;nI++)
	{
		FILE *fOut;			
		
		unsigned long nEndOffset=0;
		if(nI<2)
		{
			nEndOffset=trx->offsets[nI+1];
		}
		if(!nEndOffset)
		{
			nEndOffset=nFilesize;
		}		
		fprintf(stderr," Writing %s of size %d from offset %d ...\n", 
			pszTemp, 
			nEndOffset-READ32_LE(trx->offsets[nI]),
			READ32_LE(trx->offsets[nI]));		
		
		switch(IdentifySegment(pData+READ32_LE(trx->offsets[nI]),
			nEndOffset-READ32_LE(trx->offsets[nI])))
		{
			case SEGMENT_TYPE_SQUASHFS_3_0:
				fprintf(stderr, " SQUASHFS v3.0 image detected\n");
				sprintf(pszTemp,"%s/squashfs-lzma-image_3-0",pszOutFolder);
				break;
			case SEGMENT_TYPE_SQUASHFS_3_1:
				fprintf(stderr, " SQUASHFS v3.1 image detected\n");
				sprintf(pszTemp,"%s/squashfs-lzma-image_3-1",pszOutFolder);
				break;
			case SEGMENT_TYPE_SQUASHFS_OTHER:
				fprintf(stderr, " ! WARNING: Unknown squashfs version.\n");
				sprintf(pszTemp,"%s/squashfs-lzma-image_x-x",pszOutFolder);
				break;
			default:
				sprintf(pszTemp,"%s/segment%d",pszOutFolder,nI);
				break;			
		}		
		fOut=fopen(pszTemp,"wb");
		if(!fOut)
		{
			fprintf(stderr," ERROR could not open %s\n", pszTemp);
			free(pData);
			free(pszOutFolder);	
			free(pszTemp);
			exit(3);		
		}				
		if(!fwrite(pData+READ32_LE(trx->offsets[nI]),1,
			nEndOffset-READ32_LE(trx->offsets[nI]),fOut))
		{
			fprintf(stderr," ERROR could not write %s\n", pszTemp);
			fclose(fOut);
			free(pData);
			free(pszOutFolder);	
			free(pszTemp);
			exit(4);				
		}
		fclose(fOut);	
	}
	
	delete pszTemp;		
	free(pData);
	free(pszOutFolder);	
	free(pszTemp);
	printf(" Done!\n");
	exit(0);
}
