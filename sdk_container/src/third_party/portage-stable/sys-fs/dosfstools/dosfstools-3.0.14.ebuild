# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/dosfstools/dosfstools-3.0.14.ebuild,v 1.2 2013/01/24 04:23:26 ssuominen Exp $

EAPI="5"

inherit toolchain-funcs flag-o-matic eutils

DESCRIPTION="DOS filesystem tools - provides mkdosfs, mkfs.msdos, mkfs.vfat"
HOMEPAGE="http://www.daniel-baumann.ch/software/dosfstools/"
SRC_URI="http://www.daniel-baumann.ch/files/software/${PN}/${P}.tar.xz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~x86-linux"
IUSE=""
RESTRICT="test" # there is no test target #239071

src_prepare() {
	epatch "${FILESDIR}"/${PN}-3.0.12-name-ext.patch
	epatch "${FILESDIR}"/${PN}-3.0.13-reserved-sectors-hack.patch #434938
	sed -i \
		-e "/^PREFIX/s:=.*:= ${EPREFIX}/usr:" \
		-e '/^OPTFLAGS/d' \
		-e '/^DEBUGFLAGS/d' \
		Makefile || die
	append-lfs-flags
	tc-export CC
}

src_install() {
	default
	mv "${ED}"/usr/share/doc/{${PN},${PF}} || die
}
