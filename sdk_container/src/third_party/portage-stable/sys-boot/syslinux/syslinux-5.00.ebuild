# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-boot/syslinux/syslinux-5.00.ebuild,v 1.3 2013/01/11 17:24:42 zerochaos Exp $

EAPI=4

inherit eutils toolchain-funcs

DESCRIPTION="SYSLINUX, PXELINUX, ISOLINUX, EXTLINUX and MEMDISK bootloaders"
HOMEPAGE="http://syslinux.zytor.com/"
SRC_URI="mirror://kernel/linux/utils/boot/syslinux/${PV:0:1}.xx/${P/_/-}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
IUSE="custom-cflags"

RDEPEND="sys-fs/mtools
		dev-perl/Crypt-PasswdMD5
		dev-perl/Digest-SHA1"
DEPEND="${RDEPEND}
	dev-lang/nasm
	virtual/os-headers"

S=${WORKDIR}/${P/_/-}

# This ebuild is a departure from the old way of rebuilding everything in syslinux
# This departure is necessary since hpa doesn't support the rebuilding of anything other
# than the installers.

# These are executables which come precompiled and are run by the boot loader
QA_PREBUILT="usr/share/${PN}/*.c32"

# removed all the unpack/patching stuff since we aren't rebuilding the core stuff anymore

src_prepare() {
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
	fi

}

src_compile() {
	emake CC=$(tc-getCC) installer
}

src_install() {
	emake INSTALLSUBDIRS=utils INSTALLROOT="${D}" MANDIR=/usr/share/man install
	dodoc README NEWS doc/*.txt
}
