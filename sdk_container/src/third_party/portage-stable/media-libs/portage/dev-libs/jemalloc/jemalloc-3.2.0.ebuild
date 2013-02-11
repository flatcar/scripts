# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/jemalloc/jemalloc-3.2.0.ebuild,v 1.3 2012/12/29 19:28:18 armin76 Exp $

EAPI=4

inherit autotools eutils

DESCRIPTION="Jemalloc is a general-purpose scalable concurrent allocator"
HOMEPAGE="http://www.canonware.com/jemalloc/"
SRC_URI="http://www.canonware.com/download/${PN}/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~x86"

IUSE="debug static-libs stats"

DEPEND=""
RDEPEND=""

src_prepare() {
	epatch \
		"${FILESDIR}/${PN}-3.0.0-strip-optimization.patch" \
		"${FILESDIR}/${PN}-3.0.0-no-pprof.patch" \
		"${FILESDIR}/${PN}-3.0.0_fix_html_install.patch"

	eautoreconf
}

src_configure() {
	econf \
		$(use_enable debug) \
		$(use_enable stats)
}

src_install() {
	emake DESTDIR="${ED}" install || die
	dodoc ChangeLog README
	dohtml doc/jemalloc.html

	use static-libs || find "${ED}" -name '*.a' -exec rm -f {} +
}
