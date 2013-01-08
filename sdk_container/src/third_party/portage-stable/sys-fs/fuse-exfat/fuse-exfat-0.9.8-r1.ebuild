# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/fuse-exfat/fuse-exfat-0.9.8-r1.ebuild,v 1.4 2013/01/09 19:23:14 vapier Exp $

EAPI=4
inherit scons-utils udev toolchain-funcs eutils

DESCRIPTION="exFAT filesystem FUSE module"
HOMEPAGE="http://code.google.com/p/exfat/"
SRC_URI="http://exfat.googlecode.com/files/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="arm amd64 x86"
IUSE=""

RDEPEND="sys-fs/fuse"
DEPEND="${RDEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-0.9.8-build-vars.patch
}

src_compile() {
	tc-export AR CC RANLIB
	escons CCFLAGS="${CFLAGS}"
}

src_install() {
	dosbin fuse/mount.exfat-fuse
	dosym mount.exfat-fuse /usr/sbin/mount.exfat

	doman */*.8
	dodoc ChangeLog

	udev_dorules "${FILESDIR}"/99-exfat.rules
}
