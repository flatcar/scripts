# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/eject/eject-2.1.5-r2.ebuild,v 1.10 2010/02/01 19:35:44 ssuominen Exp $

inherit eutils

DESCRIPTION="A command to eject a disc from the CD-ROM drive"
HOMEPAGE="http://eject.sourceforge.net/"
SRC_URI="mirror://gentoo/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
IUSE="nls"

S=${WORKDIR}/${PN}

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}/${PN}"-2.0.13-xmalloc.patch
	epatch "${FILESDIR}/${PN}"-2.1.4-scsi-rdwr.patch
	epatch "${FILESDIR}/${PN}"-2.1.5-handle-spaces.patch #151257
	epatch "${FILESDIR}/${PN}"-2.1.5-man-typo.patch #165248
	epatch "${FILESDIR}/${PN}"-2.1.5-toggle.patch #261880
}

src_compile() {
	econf \
		$(use_enable nls)

	emake || die
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc ChangeLog README PORTING TODO AUTHORS NEWS PROBLEMS
}
