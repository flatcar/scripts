# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libdnet/libdnet-1.12.ebuild,v 1.3 2012/10/10 18:17:08 jer Exp $

EAPI=4

AT_M4DIR="config"
AUTOTOOLS_AUTORECONF=1
AUTOTOOLS_IN_SOURCE_BUILD=1
PYTHON_DEPEND="python? 2"

inherit autotools-utils eutils python

DESCRIPTION="simplified, portable interface to several low-level networking routines"
HOMEPAGE="http://code.google.com/p/libdnet/"
SRC_URI="http://libdnet.googlecode.com/files/${P}.tgz
	ipv6? ( http://fragroute-ipv6.googlecode.com/files/${P}.ipv6-1.patch.gz )"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
IUSE="ipv6 python static-libs test"

#DEPEND="test? ( dev-libs/check )"
RESTRICT="test"

DOCS=( README THANKS TODO )

pkg_setup() {
	if use python; then
		python_set_active_version 2
		python_pkg_setup
	fi
}

src_prepare() {
	# Useless copy
	rm -r trunk/ || die

	sed -i -e 's/libcheck.a/libcheck.so/g' configure.in || die "sed failed"
	use ipv6 && epatch "${WORKDIR}/${P}.ipv6-1.patch"
	autotools-utils_src_prepare
}

src_configure() {
	econf \
		$(use_with python) \
		$(use_enable static-libs static)
}
