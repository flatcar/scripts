/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.ac by autoheader.  */

/* Enabling support partial device tree in libxl */
/* #undef ENABLE_PARTIAL_DEVICE_TREE */

/* Define to 1 if you have the declaration of `fdt_first_subnode', and to 0 if
   you don't. */
/* #undef HAVE_DECL_FDT_FIRST_SUBNODE */

/* Define to 1 if you have the declaration of `fdt_next_subnode', and to 0 if
   you don't. */
/* #undef HAVE_DECL_FDT_NEXT_SUBNODE */

/* Define to 1 if you have the declaration of `fdt_property_u32', and to 0 if
   you don't. */
/* #undef HAVE_DECL_FDT_PROPERTY_U32 */

/* Define to 1 if you have the `fdt_first_subnode' function. */
/* #undef HAVE_FDT_FIRST_SUBNODE */

/* Define to 1 if you have the `fdt_next_subnode' function. */
/* #undef HAVE_FDT_NEXT_SUBNODE */

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if you have the `fdt' library (-lfdt). */
/* #undef HAVE_LIBFDT */

/* Define to 1 if you have the `lzma' library (-llzma). */
/* #undef HAVE_LIBLZMA */

/* Define to 1 if you have the `yajl' library (-lyajl). */
/* #undef HAVE_LIBYAJL */

/* Define to 1 if you have the `z' library (-lz). */
/* #undef HAVE_LIBZ */

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Qemu traditional enabled */
/* #undef HAVE_QEMU_TRADITIONAL */

/* ROMBIOS enabled */
/* #undef HAVE_ROMBIOS */

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Systemd available and enabled */
/* #undef HAVE_SYSTEMD */

/* Define to 1 if you have the <sys/eventfd.h> header file. */
#define HAVE_SYS_EVENTFD_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to 1 if you have the <utmp.h> header file. */
#define HAVE_UTMP_H 1

/* Define to 1 if you have the <valgrind/memcheck.h> header file. */
/* #undef HAVE_VALGRIND_MEMCHECK_H */

/* Define to 1 if you have the <yajl/yajl_version.h> header file. */
/* #undef HAVE_YAJL_YAJL_VERSION_H */

/* Define curses header to use */
/* #undef INCLUDE_CURSES_H */

/* Define extfs header to use */
/* #undef INCLUDE_EXTFS_H */

/* libutil header file name */
/* #undef INCLUDE_LIBUTIL_H */

/* IPXE path */
/* #undef IPXE_PATH */

/* OVMF path */
/* #undef OVMF_PATH */

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "xen-devel@lists.xen.org"

/* Define to the full name of this package. */
#define PACKAGE_NAME "Xen Hypervisor Tools"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "Xen Hypervisor Tools 4.14"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "xen"

/* Define to the home page for this package. */
#define PACKAGE_URL "http://www.xen.org/"

/* Define to the version of this package. */
#define PACKAGE_VERSION "4.14"

/* Qemu Xen path */
/* #undef QEMU_XEN_PATH */

/* SeaBIOS path */
/* #undef SEABIOS_PATH */

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* QMP proxy path */
/* #undef STUBDOM_QMP_PROXY_PATH */

/* Enable large inode numbers on Mac OS X 10.5.  */
#ifndef _DARWIN_USE_64_BIT_INODE
# define _DARWIN_USE_64_BIT_INODE 1
#endif

/* Number of bits in a file offset, on hosts where this is settable. */
/* #undef _FILE_OFFSET_BITS */

/* Define for large files, on AIX-style hosts. */
/* #undef _LARGE_FILES */
