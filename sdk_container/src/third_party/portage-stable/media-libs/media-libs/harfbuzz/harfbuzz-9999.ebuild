# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/harfbuzz/harfbuzz-9999.ebuild,v 1.10 2013/01/28 13:50:03 aballier Exp $

EAPI=5

EGIT_REPO_URI="git://anongit.freedesktop.org/harfbuzz"
[[ ${PV} == 9999 ]] && inherit git-2 autotools

inherit eutils libtool

DESCRIPTION="An OpenType text shaping engine"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/HarfBuzz"
[[ ${PV} == 9999 ]] || SRC_URI="http://www.freedesktop.org/software/${PN}/release/${P}.tar.bz2"

LICENSE="Old-MIT ISC icu"
SLOT="0"
[[ ${PV} == 9999 ]] || \
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-fbsd ~amd64-linux ~x86-linux ~x64-macos ~x64-solaris"
IUSE="static-libs"

RDEPEND="
	dev-libs/glib:2
	dev-libs/icu
	media-gfx/graphite2
	media-libs/freetype:2
	x11-libs/cairo
"
DEPEND="${RDEPEND}
	virtual/pkgconfig
"

src_prepare() {
	if [[ ${CHOST} == *-darwin* ]] ; then
		# on Darwin we need to link with g++, like automake defaults to,
		# but overridden by upstream because on Linux this is not
		# necessary, bug #449126
		sed -i \
			-e 's/\<LINK\>/CXXLINK/' \
			src/Makefile.am || die
		sed -i \
			-e '/libharfbuzz_la_LINK = /s/\<LINK\>/CXXLINK/' \
			src/Makefile.in || die
	fi
	[[ ${PV} == 9999 ]] && eautoreconf
	elibtoolize  # for building a shared library on x64-solaris
}

src_configure() {
	econf \
		$(use_enable static-libs static)
}

src_install() {
	default
	prune_libtool_files --all
}
