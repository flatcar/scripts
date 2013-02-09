# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libcdr/libcdr-0.0.9.ebuild,v 1.4 2012/12/08 12:27:53 maekke Exp $

EAPI=4

EGIT_REPO_URI="git://anongit.freedesktop.org/git/libreoffice/libcdr/"
inherit base
[[ ${PV} == 9999 ]] && inherit autotools git-2

DESCRIPTION="Library parsing the Corel cdr documents"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/libcdr"
[[ ${PV} == 9999 ]] || SRC_URI="http://dev-www.libreoffice.org/src/${P}.tar.xz"

LICENSE="LGPL-2.1"
SLOT="0"

# Don't move KEYWORDS on the previous line or ekeyword won't work # 399061
[[ ${PV} == 9999 ]] || \
KEYWORDS="amd64 ~arm ppc x86"

IUSE="doc static-libs"

RDEPEND="
	app-text/libwpd:0.9
	app-text/libwpg:0.2
	media-libs/lcms:2
	sys-libs/zlib
"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	sys-devel/libtool
	doc? ( app-doc/doxygen )
"

src_prepare() {
	base_src_prepare
	[[ -d m4 ]] || mkdir "m4"
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
