# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils toolchain-funcs

DESCRIPTION="SYSLINUX, PXELINUX, ISOLINUX, EXTLINUX and MEMDISK bootloaders"
HOMEPAGE="https://syslinux.zytor.com/"
SRC_URI_DIR="${PV:0:1}.xx"
SRC_URI="https://www.kernel.org/pub/linux/utils/boot/syslinux/${SRC_URI_DIR}/${P/_/-}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* amd64 x86"
IUSE="custom-cflags +perl"

RDEPEND="sys-apps/util-linux
		sys-fs/mtools
		perl? (
			dev-lang/perl
			dev-perl/Crypt-PasswdMD5
			virtual/perl-Digest-SHA
		)"
DEPEND="${RDEPEND}
	dev-lang/nasm
	virtual/os-headers"

S=${WORKDIR}/${P/_/-}

# This ebuild is a departure from the old way of rebuilding everything in syslinux
# This departure is necessary since hpa doesn't support the rebuilding of anything other
# than the installers.

# removed all the unpack/patching stuff since we aren't rebuilding the core stuff anymore

src_unpack() {
	unpack ${A}
	cd "${S}"
	# Fix building on hardened
	epatch "${FILESDIR}"/${PN}-4.05-nopie.patch

	rm -f gethostip #bug 137081

	# Don't prestrip or override user LDFLAGS, bug #305783
	local SYSLINUX_MAKEFILES="extlinux/Makefile linux/Makefile mtools/Makefile \
		sample/Makefile utils/Makefile"
	sed -i ${SYSLINUX_MAKEFILES} -e '/^LDFLAGS/d' || die "sed failed"

	if use custom-cflags; then
		sed -i ${SYSLINUX_MAKEFILES} \
			-e 's|-g -Os||g' \
			-e 's|-Os||g' \
			-e 's|CFLAGS[[:space:]]\+=|CFLAGS +=|g' \
			|| die "sed custom-cflags failed"
	else
		QA_FLAGS_IGNORED="
			/sbin/extlinux
			/usr/bin/memdiskfind
			/usr/bin/gethostip
			/usr/bin/isohybrid
			/usr/bin/syslinux
			"
	fi

	# Don't build/install scripts if perl is disabled
	if ! use perl; then
		sed -i utils/Makefile \
			-e 's/$(TARGETS)/$(C_TARGETS)/' \
			-e 's/$(ASIS)//' \
			|| die "sed remove perl failed"
		rm man/{lss16toppm.1,ppmtolss16.1,syslinux2ansi.1} || die
	fi

	# COREOS: Define the major/minor macros with newer glibc versions.
	sed -i -e '/vfs/a#include <sys/sysmacros.h>' extlinux/main.c
}

src_compile() {
	emake CC="$(tc-getCC)" installer || die
}

src_install() {
	emake INSTALLSUBDIRS=utils INSTALLROOT="${D}" MANDIR=/usr/share/man install || die
	dodoc README NEWS doc/*.txt || die
}
