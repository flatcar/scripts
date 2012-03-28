# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/tiff/tiff-4.0.0-r1.ebuild,v 1.6 2012/02/15 02:12:12 ssuominen Exp $

EAPI=4
inherit eutils libtool

DESCRIPTION="Library for manipulation of TIFF (Tag Image File Format) images"
HOMEPAGE="http://www.remotesensing.org/libtiff/"
SRC_URI="http://download.osgeo.org/libtiff/${P}.tar.gz
	ftp://ftp.remotesensing.org/pub/libtiff/${P}.tar.gz"

LICENSE="as-is"
SLOT="0"
KEYWORDS="~alpha amd64 arm hppa ~ia64 ~m68k ~mips ppc ppc64 ~s390 ~sh ~sparc x86 ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="+cxx jbig jpeg lzma static-libs zlib"

RDEPEND="jpeg? ( virtual/jpeg )
	jbig? ( media-libs/jbigkit )
	lzma? ( app-arch/xz-utils )
	zlib? ( sys-libs/zlib )"
DEPEND="${RDEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/${P}-missing_lzma_pkgconfig.patch #396531
	elibtoolize
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_enable zlib) \
		$(use_enable jpeg) \
		$(use_enable jbig) \
		$(use_enable lzma) \
		$(use_enable cxx) \
		--without-x \
		--with-docdir="${EPREFIX}"/usr/share/doc/${PF}
}

src_install() {
	default

	rm -f \
		"${ED}"/usr/lib*/libtiff*.la \
		"${ED}"/usr/share/doc/${PF}/{COPYRIGHT,README*,RELEASE-DATE,TODO,VERSION}
}
