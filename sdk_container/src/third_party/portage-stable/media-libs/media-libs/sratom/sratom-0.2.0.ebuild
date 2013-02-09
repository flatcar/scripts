# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/sratom/sratom-0.2.0.ebuild,v 1.3 2012/05/22 16:04:12 johu Exp $

EAPI=4

inherit waf-utils

DESCRIPTION="Library for serialising LV2 atoms to/from RDF, particularly the Turtle syntax"
HOMEPAGE="http://drobilla.net/software/sratom/"
SRC_URI="http://download.drobilla.net/${P}.tar.bz2"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc static-libs test"

RDEPEND="media-libs/lv2
	>=dev-libs/serd-0.14.0
	>=dev-libs/sord-0.8.0"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	virtual/pkgconfig"

PATCHES=( "${FILESDIR}/ldconfig.patch" )
DOCS=( "NEWS" "README" )

src_configure() {
	waf-utils_src_configure \
		--docdir=/usr/share/doc/${PF} \
		$(use test && echo "--test") \
		$(use doc && echo "--docs") \
		$(use static-libs && echo "--static")
}

src_test() {
	./waf test || die
}
