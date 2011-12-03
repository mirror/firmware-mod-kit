# ----------------------------Archive Formats--------------------------------------

# POSIX tar archives
257     string          ustar\000         POSIX tar archive
!:mime  application/x-tar # encoding: posix
257     string          ustar\040\040\000 GNU tar archive
!:mime  application/x-tar # encoding: gnu

# MIPS archive (needs to go before regular portable archives)
#
0       string  =!<arch>\n__________E   MIPS archive
>20     string  U                       with MIPS Ucode members
>21     string  L                       with MIPSEL members
>21     string  B                       with MIPSEB members
>19     string  L                       and an EL hash table
>19     string  B                       and an EB hash table
>22     string  X                       -- out of date

# JAR archiver (.j), this is the successor to ARJ, not Java's JAR (which is essentially ZIP)
0xe     string  \x1aJar\x1b JAR (ARJ Software, Inc.) archive data
0       string  JARCS JAR (ARJ Software, Inc.) archive data


# ARJ archiver (jason@jarthur.Claremont.EDU)
0       leshort         0xea60          ARJ archive data
!:mime  application/x-arj
>5      byte            x               \b, v%d,
>8      byte            &0x04           multi-volume,
>8      byte            &0x10           slash-switched,
>8      byte            &0x20           backup,
>34     string          x               original name: %s,
>7      byte            0               os: MS-DOS 
>7      byte            1               os: PRIMOS
>7      byte            2               os: Unix
>7      byte            3               os: Amiga
>7      byte            4               os: Macintosh
>7      byte            5               os: OS/2
>7      byte            6               os: Apple ][ GS
>7      byte            7               os: Atari ST
>7      byte            8               os: NeXT
>7      byte            9               os: VAX/VMS
>3      byte            >0              %d]
# [JW] idarc says this is also possible
2       leshort         0xea60          ARJ archive data
>5      byte            x               \b, v%d,
>8      byte            &0x04           multi-volume,
>8      byte            &0x10           slash-switched,
>8      byte            &0x20           backup,
>34     string          x               original name: %s,
>7      byte            0               os: MS-DOS
>7      byte            1               os: PRIMOS
>7      byte            2               os: Unix
>7      byte            3               os: Amiga
>7      byte            4               os: Macintosh
>7      byte            5               os: OS/2
>7      byte            6               os: Apple ][ GS
>7      byte            7               os: Atari ST
>7      byte            8               os: NeXT
>7      byte            9               os: VAX/VMS
>3      byte            >0              %d]
