# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/jemalloc/jemalloc-3.3.0.ebuild,v 1.2 2013/01/28 20:17:28 vapier Exp $

EAPI=4

inherit autotools eutils

DESCRIPTION="Jemalloc is a general-purpose scalable concurrent allocator"
HOMEPAGE="http://www.canonware.com/jemalloc/"
SRC_URI="http://www.canonware.com/download/${PN}/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~x86"
IUSE="debug static-libs stats"

src_prepare() {
	epatch \
		"${FILESDIR}/${PN}-3.0.0-strip-optimization.patch" \
		"${FILESDIR}/${PN}-3.0.0-no-pprof.patch" \
		"${FILESDIR}/${PN}-3.0.0_fix_html_install.patch" \
		"${FILESDIR}/${PN}-3.3.0-s390.patch"

	eautoreconf
}

src_configure() {
	econf \
		$(use_enable debug) \
		$(use_enable stats)
}

src_install() {
	default
	dohtml doc/jemalloc.html

	use static-libs || find "${ED}" -name '*.a' -delete
}
