# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/dvutil/dvutil-1.0.10-r2.ebuild,v 1.2 2012/05/04 18:35:45 jdhore Exp $

EAPI=4
inherit autotools eutils

DESCRIPTION="C++ classes for files, dates, property lists, reference counted pointers, number conversion etc."
HOMEPAGE="http://tinf2.vub.ac.be/~dvermeir/software/dv/dvutil/html/"
SRC_URI="http://tinf2.vub.ac.be/~dvermeir/software/dv/${PN}/download/${P}.tar.gz
	mirror://gentoo/${P}-asneeded.patch.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~sparc ~x86"
IUSE="doc ssl static-libs"

RDEPEND="ssl? ( dev-libs/openssl:0 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

DOCS="AUTHORS ChangeLog NEWS README"

src_prepare() {
	epatch "${WORKDIR}"/${P}-asneeded.patch
	sed -i -e '/LDFLAGS.*all-static/d' dvutil/Makefile.am || die #362669
	eautoreconf
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_with ssl)
}

src_install() {
	default
	use doc && dohtml -r doc/html/*

	# Keeping .la files in purpose, see: http://bugs.gentoo.org/409125
	find "${ED}" -name '*.la' -exec sed -i -e "/^dependency_libs/s:=.*:='':" {} +
}
