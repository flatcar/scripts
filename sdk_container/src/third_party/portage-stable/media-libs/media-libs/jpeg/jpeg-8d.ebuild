# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/jpeg/jpeg-8d.ebuild,v 1.6 2012/12/16 16:12:57 ulm Exp $

EAPI=4
inherit eutils libtool toolchain-funcs

MY_PN=libjpeg8
MY_PV=1

DESCRIPTION="Library to load, handle and manipulate images in the JPEG format"
HOMEPAGE="http://jpegclub.org/ http://www.ijg.org/"
SRC_URI="http://www.ijg.org/files/${PN}src.v${PV}.tar.gz
	mirror://debian/pool/main/${MY_PN:0:4}/${MY_PN}/${MY_PN}_${PV}-${MY_PV}.debian.tar.gz"

LICENSE="IJG"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="static-libs"

DOCS="change.log example.c README *.txt"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-7-maxmem_sysconf.patch
	elibtoolize
}

src_configure() {
	# Fix building against this library on eg. Solaris and DragonFly BSD, see:
	# http://mail-index.netbsd.org/pkgsrc-bugs/2010/01/18/msg035644.html
	local ldverscript=
	[[ ${CHOST} == *-solaris* ]] && ldverscript="--disable-ld-version-script"

	econf \
		$(use_enable static-libs static) \
		--enable-maxmem=64 \
		${ldverscript}
}

src_compile() {
	default

	# Build exifautotran and jpegexiforient
	cd ../debian/extra
	emake CC="$(tc-getCC)" CFLAGS="${LDFLAGS} ${CFLAGS}"
}

src_install() {
	default

	find "${ED}" -name '*.la' -exec rm -f {} +

	# Install exifautotran and jpegexiforient
	newdoc ../debian/changelog changelog.debian
	cd ../debian/extra
	emake \
		DESTDIR="${D}" prefix="${EPREFIX}"/usr \
		INSTALL="install -m755" INSTALLDIR="install -d -m755" \
		install
}

pkg_postinst() {
	ewarn "If you are switching from media-libs/libjpeg-turbo you might need to"
	ewarn "rebuild reverse dependencies:"
	ewarn
	ewarn "# emerge gentoolkit"
	ewarn "# revdep-rebuild --library libjpeg.so.8"
}
