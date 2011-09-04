#include <arpa/inet.h>
#include "patch.h"
#include "crc.h"

/* Update the CRC for a TRX file */
int patch_trx(char *buf)
{
        int retval = 0;
        struct trx_header *header = NULL;

        header = (struct trx_header *) buf;
        header->crc32 = 0;

        /* Checksum is calculated over the image, plus the header offsets (12 bytes into the TRX header) */
        header->crc32 = crc32(buf+12, (header->len-12));

        if(header->crc32 != 0)
        {
                retval = 1;
        }

        return retval;
}

/* Update both CRCs for uImage files */
int patch_uimage(char *buf)
{
        int retval = 0;
        struct uimage_header *header = NULL;

        header = (struct uimage_header *) buf;

        header->ih_hcrc = 0;
        header->ih_dcrc = 0;

        header->ih_dcrc = crc32(buf+sizeof(struct uimage_header), ntohl(header->ih_size)) ^ 0xFFFFFFFFL;
        header->ih_dcrc = htonl(header->ih_dcrc);

        header->ih_hcrc = crc32(buf, sizeof(struct uimage_header)) ^ 0xFFFFFFFFL;
        header->ih_hcrc = htonl(header->ih_hcrc);

        if(header->ih_dcrc != 0 && header->ih_hcrc != 0)
        {
                retval = 1;
        }

        return retval;
}
