# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libevocosm/libevocosm-3.3.0.ebuild,v 1.3 2009/02/26 14:53:19 josejx Exp $

inherit eutils

DESCRIPTION="A C++ framework for evolutionary computing"
HOMEPAGE="http://www.coyotegulch.com/products/libevocosm/"
SRC_URI="http://www.coyotegulch.com/distfiles/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE="doc"

RDEPEND="dev-libs/libcoyotl
	dev-libs/libbrahe"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}/${PV}-gcc-4.3.patch"
}

src_compile() {
	ac_cv_prog_HAVE_DOXYGEN="false" econf || die "econf failed"
	emake || die "emake failed"

	if use doc ; then
		cd docs
		doxygen libevocosm.doxygen || die "generating docs failed"
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc AUTHORS ChangeLog NEWS README
	dohtml docs/html/*
}
