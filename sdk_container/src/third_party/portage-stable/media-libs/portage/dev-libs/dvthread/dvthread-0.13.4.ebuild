# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/dvthread/dvthread-0.13.4.ebuild,v 1.3 2012/03/21 10:28:46 ssuominen Exp $

EAPI=4

DESCRIPTION="Classes for threads and monitors, wrapped around the posix thread library"
HOMEPAGE="http://tinf2.vub.ac.be/~dvermeir/software/dv/dvthread/html/"
SRC_URI="http://tinf2.vub.ac.be/~dvermeir/software/dv/${PN}/download/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="doc static-libs"

RDEPEND=">=dev-libs/dvutil-1.0.10-r2"
DEPEND="${RDEPEND}"

DOCS="AUTHORS ChangeLog NEWS"

src_prepare() {
	sed -i -e 's:dvthread doc m4:dvthread m4:' Makefile.in || die
}

src_configure() {
	econf $(use_enable static-libs static)
}

src_install() {
	default

	if use doc; then
		doman doc/man/man3/*.3
		dohtml -r doc/html/*
	fi

	# Keeping .la files in purpose, see: http://bugs.gentoo.org/409125
	find "${ED}" -name '*.la' -exec sed -i -e "/^dependency_libs/s:=.*:='':" {} +
}
