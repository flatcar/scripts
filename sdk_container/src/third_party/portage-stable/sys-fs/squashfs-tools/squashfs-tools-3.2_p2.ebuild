# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/squashfs-tools/squashfs-tools-3.2_p2.ebuild,v 1.8 2010/11/14 13:49:59 jlec Exp $

inherit toolchain-funcs

MY_PV=${PV/_p/-r}
DESCRIPTION="Tool for creating compressed filesystem type squashfs"
HOMEPAGE="http://squashfs.sourceforge.net/"
SRC_URI="mirror://sourceforge/squashfs/squashfs${MY_PV}.tar.gz"

LICENSE="GPL-2"
SLOT="3.0" # squashfs filesystem version
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
IUSE=""

RDEPEND="sys-libs/zlib"

S=${WORKDIR}/squashfs${MY_PV}/squashfs-tools

src_unpack() {
	unpack ${A}
	cd "${S}"
	sed -i \
		-e 's:-O2:$(CFLAGS):' \
		-e '/-lz/s:$: $(LDFLAGS):' \
		Makefile
	echo "struct dir_info; `grep '^int dir_scan2' mksquashfs.c`;" >> global.h
}

src_compile() {
	emake CC="$(tc-getCC)" || die
}

src_install() {
	newbin mksquashfs mksquashfs-${SLOT} || die
	newbin unsquashfs unsquashfs-${SLOT} || die
	cd ..
	dodoc README ACKNOWLEDGEMENTS CHANGES PERFORMANCE.README README-3.2 || die
}
