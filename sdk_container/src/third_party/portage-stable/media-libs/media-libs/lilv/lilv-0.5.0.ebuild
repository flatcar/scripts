# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/lilv/lilv-0.5.0.ebuild,v 1.5 2012/05/05 08:02:30 jdhore Exp $

EAPI=4

inherit base waf-utils

DESCRIPTION="Library to make the use of LV2 plugins as simple as possible for applications"
HOMEPAGE="http://drobilla.net/software/lilv/"
SRC_URI="http://download.drobilla.net/${P}.tar.bz2"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc test"

RDEPEND="|| ( media-libs/lv2 >=media-libs/lv2core-6 )
	>=dev-libs/serd-0.5
	>=dev-libs/sord-0.5"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	virtual/pkgconfig"

PATCHES=( "${FILESDIR}/ldconfig.patch" )
DOCS=( "AUTHORS" "README" "ChangeLog" )

src_configure() {
	waf-utils_src_configure \
		"--mandir=/usr/share/man" \
		"--docdir=/usr/share/doc/${PF}" \
		$(use test && echo "--test") \
		$(use doc && echo "--docs")
	#$(use dyn-manifest && echo "--dyn-manifest") \
}

src_test() {
	./waf test || die
}
