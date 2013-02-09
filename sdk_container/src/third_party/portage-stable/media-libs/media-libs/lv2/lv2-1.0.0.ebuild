# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/lv2/lv2-1.0.0.ebuild,v 1.3 2012/05/22 15:37:39 johu Exp $

EAPI=4

inherit waf-utils

DESCRIPTION="LV2 is a simple but extensible successor of LADSPA"
HOMEPAGE="http://lv2plug.in/"
SRC_URI="http://lv2plug.in/spec/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc plugins"

DEPEND="plugins? ( x11-libs/gtk+:2 media-libs/libsndfile )"
RDEPEND="${DEPEND}
	!<media-libs/slv2-0.4.2
	!media-libs/lv2core
	!media-libs/lv2-ui"
DEPEND="${DEPEND}
	plugins? ( virtual/pkgconfig )
	doc? ( app-doc/doxygen dev-python/rdflib )"
DOCS=( "README" "NEWS" )

src_configure() {
	waf-utils_src_configure \
		--docdir="${EPREFIX}"/usr/share/doc/${PF} \
		$(use plugins || echo " --no-plugins") \
		$(use doc     && echo " --docs"      )
}
