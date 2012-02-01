# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/tiff/tiff-3.9.2-r1.ebuild,v 1.7 2010/03/09 21:46:10 josejx Exp $

EAPI=2
inherit eutils libtool

DESCRIPTION="Library for manipulation of TIFF (Tag Image File Format) images"
HOMEPAGE="http://www.remotesensing.org/libtiff/"
SRC_URI="ftp://ftp.remotesensing.org/pub/libtiff/${P}.tar.gz"

LICENSE="as-is"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="jpeg jbig +cxx zlib"

DEPEND="jpeg? ( >=media-libs/jpeg-6b:0 )
	jbig? ( media-libs/jbigkit )
	zlib? ( sys-libs/zlib )"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-3.8.2-CVE-2009-2285.patch \
		"${FILESDIR}"/${P}-CVE-2009-2347.patch
	elibtoolize
}

src_configure() {
	use prefix || EPREFIX=
	econf \
		--disable-dependency-tracking \
		$(use_enable cxx) \
		$(use_enable zlib) \
		$(use_enable jpeg) \
		$(use_enable jbig) \
		--without-x \
		--with-docdir="${EPREFIX}"/usr/share/doc/${PF}
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc ChangeLog README TODO
}

pkg_postinst() {
	if use jbig; then
		echo
		elog "JBIG support is intended for Hylafax fax compression, so we"
		elog "really need more feedback in other areas (most testing has"
		elog "been done with fax).  Be sure to recompile anything linked"
		elog "against tiff if you rebuild it with jbig support."
		echo
	fi
}
