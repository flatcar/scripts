# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/dos2unix/dos2unix-5.3.1.ebuild,v 1.9 2012/03/03 16:02:04 ranger Exp $

EAPI=4

inherit eutils toolchain-funcs

DESCRIPTION="Convert DOS or MAC text files to UNIX format or vice versa"
HOMEPAGE="http://www.xs4all.nl/~waterlan/dos2unix.html http://sourceforge.net/projects/dos2unix/"
SRC_URI="
	http://www.xs4all.nl/~waterlan/${PN}/${P}.tar.gz
	mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~sparc64-solaris"
IUSE="debug nls"

RDEPEND="
	!app-text/hd2u
	!app-text/unix2dos
	virtual/libintl"
DEPEND="
	${RDEPEND}
	dev-lang/perl"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-5.3.1-fix_debug_build.patch

	sed \
		-e '/^LDFLAGS/s|=|+=|' \
		-e '/^CC/s|=|?=|' \
		-e '/CFLAGS_OS \+=/d' \
		-e '/LDFLAGS_EXTRA \+=/d' \
		-e "/^CFLAGS/s|-O2|${CFLAGS}|" \
		-i "${S}"/Makefile || die
	tc-export CC
	use debug && sed "/DEBUG/s:0:1:g" -i Makefile
}

lintl() {
	# same logic as from virtual/libintl
	use !elibc_glibc && use !elibc_uclibc && echo "-lintl"
}

src_compile() {
	emake prefix="${EPREFIX}/usr" \
		$(use nls && echo "LDFLAGS_EXTRA=$(lintl)" || echo "ENABLE_NLS=")
}

src_install() {
	emake DESTDIR="${D}" prefix="${EPREFIX}/usr" \
		$(use nls || echo "ENABLE_NLS=") install
}
