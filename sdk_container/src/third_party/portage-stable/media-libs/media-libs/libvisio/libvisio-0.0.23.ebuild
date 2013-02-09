# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libvisio/libvisio-0.0.23.ebuild,v 1.3 2012/12/08 12:10:41 maekke Exp $

EAPI=5

EGIT_REPO_URI="git://anongit.freedesktop.org/git/libreoffice/contrib/libvisio/"
inherit base
[[ ${PV} == 9999 ]] && inherit autotools git-2

DESCRIPTION="Library parsing the visio documents"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/libvisio"
[[ ${PV} == 9999 ]] || SRC_URI="http://dev-www.libreoffice.org/src/${P}.tar.xz"

LICENSE="LGPL-2.1"
SLOT="0"
[[ ${PV} == 9999 ]] || \
KEYWORDS="amd64 ~arm ppc x86"
IUSE="doc static-libs"

RDEPEND="
	app-text/libwpd:0.9
	app-text/libwpg:0.2
	dev-libs/libxml2
	sys-libs/zlib
"
DEPEND="${RDEPEND}
	>=dev-libs/boost-1.46
	dev-util/gperf
	sys-devel/libtool
	virtual/pkgconfig
	doc? ( app-doc/doxygen )
"

src_prepare() {
	[[ -d m4 ]] || mkdir "m4"
	base_src_prepare
	[[ ${PV} == 9999 ]] && eautoreconf
}

src_configure() {
	econf \
		--docdir="${EPREFIX}/usr/share/doc/${PF}" \
		$(use_enable static-libs static) \
		--disable-werror \
		$(use_with doc docs)
}

src_install() {
	default
	find "${ED}" -name '*.la' -exec rm -f {} +
}
