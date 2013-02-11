# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/eb/eb-4.4.1.ebuild,v 1.7 2012/08/05 17:53:28 armin76 Exp $

IUSE="nls ipv6 threads"

DESCRIPTION="EB is a C library and utilities for accessing CD-ROM books"
HOMEPAGE="http://www.sra.co.jp/people/m-kasahr/eb/"
SRC_URI="ftp://ftp.sra.co.jp/pub/misc/eb/${P}.tar.lzma"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86"

RDEPEND="sys-libs/zlib
	nls? ( virtual/libintl )"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )"

src_compile () {
	econf \
		--with-pkgdocdir=/usr/share/doc/${PF}/html \
		$(use_enable nls) \
		$(use_enable threads pthread) \
		$(use_enable ipv6) || die "Failed configure."
	emake || die "Failed make."
}

src_install () {
	emake DESTDIR="${D}" install || die "Failed install."

	dodoc AUTHORS ChangeLog* NEWS README
}

pkg_postinst() {
	elog
	elog "If you are upgrading from <app-dicts/eb-4.4.1,"
	elog "you may need to rebuild applications depending on eb."
	elog
}
