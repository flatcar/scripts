# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-boot/syslinux/syslinux-4.05.ebuild,v 1.5 2012/05/28 08:47:21 chithanh Exp $

inherit eutils toolchain-funcs

DESCRIPTION="SYSLINUX, PXELINUX, ISOLINUX, EXTLINUX and MEMDISK bootloaders"
HOMEPAGE="http://syslinux.zytor.com/"
SRC_URI="mirror://kernel/linux/utils/boot/syslinux/${PV:0:1}.xx/${P/_/-}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* amd64 x86"
IUSE="custom-cflags"

RDEPEND="sys-fs/mtools
		dev-perl/Crypt-PasswdMD5
		dev-perl/Digest-SHA1"
DEPEND="${RDEPEND}
	dev-lang/nasm
	<sys-kernel/linux-headers-3.4"

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

	# Fix building with --as-needed
	epatch "${FILESDIR}"/${PN}-4.05-asneeded-linking-order.patch

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
	emake CC=$(tc-getCC) installer || die
}

src_install() {
	emake INSTALLSUBDIRS=utils INSTALLROOT="${D}" MANDIR=/usr/share/man install || die
	dodoc README NEWS doc/*.txt || die
}
