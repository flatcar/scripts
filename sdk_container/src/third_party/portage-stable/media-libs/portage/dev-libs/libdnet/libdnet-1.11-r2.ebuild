# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libdnet/libdnet-1.11-r2.ebuild,v 1.10 2012/07/08 17:29:47 armin76 Exp $

EAPI=4
PYTHON_DEPEND="python? 2"
inherit autotools eutils python

DESCRIPTION="simplified, portable interface to several low-level networking routines"
HOMEPAGE="http://libdnet.sourceforge.net/"
SRC_URI="mirror://sourceforge/libdnet/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="alpha amd64 ~arm hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd"
IUSE="python static-libs"

RESTRICT="test"
DOCS=( README THANKS TODO )

pkg_setup() {
	if use python; then
		python_set_active_version 2
		python_pkg_setup
	fi
}

src_prepare() {
	sed -i 's/suite_free(s);//' test/check/*.c || die "sed failed"
	epatch "${FILESDIR}"/${PN}-1.10-gcc4.diff
	AT_M4DIR="config"
	eautoreconf
}

src_configure() {
	econf $(use_with python) $(use_enable static-libs static)
}

src_install() {
	default
	if ! use static-libs; then
		rm -f "${D}"/usr/lib*/*.la || die
	fi
}
