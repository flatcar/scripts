# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/vflib/vflib-3.6.14.ebuild,v 1.6 2008/09/02 23:45:55 aballier Exp $

inherit libtool eutils

MY_P=VFlib3-${PV}

DESCRIPTION="Japanese Vector Font library"
HOMEPAGE="http://www-masu.ist.osaka-u.ac.jp/~kakugawa/VFlib/"
SRC_URI="http://www-masu.ist.osaka-u.ac.jp/~kakugawa/download/TypeHack/${MY_P}.tar.gz"

LICENSE="LGPL-2 GPL-2"
SLOT="3"
KEYWORDS="~alpha ~amd64 ~ppc ~sparc ~x86"
IUSE=""

RDEPEND="x11-libs/libX11
	x11-libs/libXau
	x11-libs/libXdmcp
	x11-libs/libXext
	=media-libs/freetype-1*
	virtual/tex-base
	media-libs/t1lib"
DEPEND="${RDEPEND}
	x11-proto/xproto
	x11-misc/imake"

S="${WORKDIR}"/${MY_P}

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-install-info.diff
	elibtoolize
}

src_compile() {
	sed -i -e "s:<varargs.h>:<stdarg.h>:" src/vfldisol.c
	if has_version '>=media-libs/t1lib-5' ; then
		sed -i -e "s:T1_Get_no_fonts:T1_GetNoFonts:" src/drv_t1.c
	fi

	econf \
		--with-kpathsea \
		--with-kpathsea-include=/usr/include \
		--with-kpathsea-libdir=/usr/$(get_libdir) \
		--with-freetype \
		--with-freetype-includedir=/usr/include/freetype \
		--with-freetype-libdir=/usr/$(get_libdir) \
		--with-t1lib \
		--with-t1lib-includedir=/usr/include \
		--with-t1lib-libdir=/usr/$(get_libdir) || die

	emake -j1 \
		CDEBUGFLAGS="${CFLAGS}" \
		CXXDEBUGFLAGS="${CXXFLAGS}" || die
}

src_install () {
	einstall \
		runtimedir="${D}"/usr/share/VFlib/${PV} \
		runtimesitedir="${D}"/usr/share/VFlib/site || die

	dodoc CHANGES COPYING* DISTRIB.txt INSTALL README*
}
