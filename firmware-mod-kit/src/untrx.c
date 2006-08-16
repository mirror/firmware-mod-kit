/* untrx
 * Copyright (C) 2006  Jeremy Collake  <jeremy@bitsum.com>
 *
 *	version: 0.27 beta		
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

/* bit size specific type fixes for msvc and other systems */
#ifndef __int8_t_defined
#ifdef __int32
	#typedef u_int32_t unsigned __int32
#else	
	#warning "u_int32_t may be undefined. please define as 32-bit type."
	//#define u_int32_t unsigned long	 /* for 32-bit builds .. */
#endif
#endif


/* stuff for quick OS X compatibility by Jeremy Collake */
#ifndef bswap_32
#define bswap_32 flip_endian
#endif

// always flip, regardless of endianness of machine
u_int32_t flip_endian(u_int32_t nValue)
{
	// my crappy endian switch
	u_int32_t nR;
	u_int32_t nByte1=(nValue&0xff000000)>>24;
	u_int32_t nByte2=(nValue&0x00ff0000)>>16;
	u_int32_t nByte3=(nValue&0x0000ff00)>>8;
	u_int32_t nByte4=nValue&0x0ff;
	nR=nByte4<<24;
	nR|=(nByte3<<16);
	nR|=(nByte2<<8);
	nR|=nByte1;
	return nR;
}

#if __BYTE_ORDER == __BIG_ENDIAN
#define STORE32_LE(X)		bswap_32(X)
#define READ32_LE(X)        bswap_32(X)
#elif __BYTE_ORDER == __LITTLE_ENDIAN
#define STORE32_LE(X)		(X)
#define READ32_LE(X)        (X)
#else
#error unkown endianness!
#endif


/**********************************************************************/
/* from trxhdr.h */

#define TRX_MAGIC	0x30524448	/* "HDR0" */

typedef struct _trx_header {
	u_int32_t magic;			/* "HDR0" */
	u_int32_t len;			/* Length of file including header */
	u_int32_t crc32;			/* 32-bit CRC from flag_version to end of file */
	u_int32_t flag_version;	/* 0:15 flags, 16:31 version */
	u_int32_t offsets[3];	/* Offsets of partitions from start of header */
} trx_header;

/**********************************************************************/

#define HDR0_SIZE (sizeof(trx_header))

// size of header added by addpattern
#define U2ND_HEADER_SIZE 32	

void ShowUsage()
{
				
	fprintf(stderr, " ERROR: Invalid usage.\n"		
		" USAGE: untrx binfile outfolder\n");
	exit(9);
}

/* main */
int main(int argc, char **argv)
{
	printf(" untrx v0.31 beta - (c)2006 Jeremy Collake\n");
	
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
	unsigned char *pDataOriginalAlloc=pData; // because we might increment pData for ease
	if(fread(pData,1,nFilesize,fIn)!=nFilesize)
	{
		fprintf(stderr," ERROR reading %s\n", argv[1]);		
		fclose(fIn);	
		free(pDataOriginalAlloc);
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
			free(pDataOriginalAlloc);
			free(pszOutFolder);	
			exit(2);			
		}
	}
	unsigned long nLoaderOffset=READ32_LE(trx->offsets[0]);
	unsigned long nKernelOffset=READ32_LE(trx->offsets[1]);
	unsigned long nSquashfsOffset=READ32_LE(trx->offsets[2]);
	
	if((nSquashfsOffset==0 || nSquashfsOffset>nFilesize) 
		|| (nKernelOffset==0 || nKernelOffset>nSquashfsOffset)
		|| (nLoaderOffset==0 || nLoaderOffset>nKernelOffset))
	{
		fprintf(stderr," ERROR partition sizes invalid\n");
		free(pDataOriginalAlloc);
		free(pszOutFolder);	
		exit(2);
	}	
	
	char *pszTemp=(char *)malloc(strlen(pszOutFolder)+128);	
	
	FILE *fOut;
	/*
		This is to fix Brainslayer changing the squashfs signature
		in dd-wrt build 08/10/06. gotta add support for whatever
		squashfs signature (a new parameter was added to mksquashfs).
	*/	
	
	sprintf(pszTemp,"%s/squashfs_magic", pszOutFolder);
	fOut=fopen(pszTemp,"wb"); 
	if(!fOut)
	{
		fprintf(stderr," ERROR could not open %s\n", pszTemp);
		free(pDataOriginalAlloc);
		free(pszOutFolder);	
		free(pszTemp);
		exit(3);		
	}
	if(fwrite(pData+nSquashfsOffset,1,4,fOut)!=4)
	{
		fprintf(stderr," ERROR could not write %s\n", pszTemp);
		free(pDataOriginalAlloc);
		free(pszOutFolder);	
		free(pszTemp);
		exit(9);	
	}
	fclose(fOut);
	
	/*
		Lame file write blocks below. Could use table and loop, but
		this is a dumb little utility, why change it now.
	*/	
	
	sprintf(pszTemp,"%s/loader", pszOutFolder);
	fOut=fopen(pszTemp,"wb"); 
	if(!fOut)
	{
		fprintf(stderr," ERROR could not open %s\n", pszTemp);
		free(pDataOriginalAlloc);
		free(pszOutFolder);	
		free(pszTemp);
		exit(3);		
	}
	printf(" Writing %s of size %u ...\n", pszTemp, nKernelOffset-nLoaderOffset);
	if(fwrite(pData+nLoaderOffset,1,nKernelOffset-nLoaderOffset,fOut)!=nKernelOffset-nLoaderOffset)
	{
		fprintf(stderr," ERROR could not write %s\n", pszTemp);
		free(pDataOriginalAlloc);
		free(pszOutFolder);	
		free(pszTemp);
		exit(6);					
	}
	fclose(fOut);
	
	sprintf(pszTemp,"%s/vmlinuz", pszOutFolder);
	fOut=fopen(pszTemp,"wb"); 
	if(!fOut)
	{
		fprintf(stderr," ERROR could not open %s\n", pszTemp);
		free(pDataOriginalAlloc);
		free(pszOutFolder);	
		free(pszTemp);
		exit(3);		
	}
	printf(" Writing %s of size %u ...\n", pszTemp, nSquashfsOffset-nKernelOffset);
	if(fwrite(pData+nKernelOffset,1,nSquashfsOffset-nKernelOffset,fOut)!=nSquashfsOffset-nKernelOffset)
	{
		fprintf(stderr," ERROR could not write %s\n", pszTemp);
		free(pDataOriginalAlloc);
		free(pszOutFolder);	
		free(pszTemp);
		exit(7);					
	}
	fclose(fOut);
		
	sprintf(pszTemp,"%s/squashfs-lzma-image", pszOutFolder);
	fOut=fopen(pszTemp,"wb"); 
	if(!fOut)
	{
		fprintf(stderr," ERROR could not open %s\n", pszTemp);
		free(pDataOriginalAlloc);
		free(pszOutFolder);	
		free(pszTemp);
		exit(4);		
	}
	printf(" Writing %s of size %u ...\n", pszTemp, nFilesize-nSquashfsOffset);
	if(fwrite(pData+nSquashfsOffset,1,nFilesize-nSquashfsOffset,fOut)!=nFilesize-nSquashfsOffset)
	{
		fprintf(stderr," ERROR could not write %s\n", pszTemp);
		free(pDataOriginalAlloc);
		free(pszOutFolder);	
		free(pszTemp);
		exit(8);			
	}
	fclose(fOut);	
	
	free(pDataOriginalAlloc);
	free(pszOutFolder);	
	free(pszTemp);
	printf(" Done!\n");
	exit(0);
}
