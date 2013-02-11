# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/tvision/tvision-2.1.0_pre2-r1.ebuild,v 1.4 2007/11/02 14:26:09 beandog Exp $

inherit eutils multilib

DESCRIPTION="Text User Interface that implements the well known CUA widgets"
HOMEPAGE="http://tvision.sourceforge.net/"
SRC_URI="mirror://sourceforge/tvision/rhtvision_${PV/_pre/-}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE=""

S=${WORKDIR}/${PN}

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-gcc41.patch
	epatch "${FILESDIR}"/${P}-outb.patch
	epatch "${FILESDIR}"/${P}-underflow.patch
	epatch "${FILESDIR}"/${P}-asneeded.patch
}

src_compile() {
	./configure \
		--prefix=/usr \
		--fhs \
		|| die
	emake || die
}

src_install() {
	einstall libdir="\$(prefix)/$(get_libdir)"|| die
	dosym rhtvision /usr/include/tvision
	dodoc readme.txt THANKS TODO
	dohtml -r www-site
}
