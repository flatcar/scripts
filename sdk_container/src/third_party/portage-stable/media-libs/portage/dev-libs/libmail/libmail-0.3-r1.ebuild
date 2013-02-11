# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libmail/libmail-0.3-r1.ebuild,v 1.3 2013/01/30 15:30:00 ago Exp $

EAPI=5

inherit autotools

DESCRIPTION="A mail handling library"
HOMEPAGE="http://libmail.sourceforge.net"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="apop gnutls profile sasl"

DEPEND="gnutls? ( >=net-libs/gnutls-2 )
	sasl? ( >=dev-libs/cyrus-sasl-2 )"
RDEPEND="${DEPEND}"

src_prepare() {
	# Drop quotes from ACLOCAL_AMFLAGS otherwise aclocal will fail
	# see 447760
	sed -i -e "/ACLOCAL_AMFLAGS/s:\"::g" Makefile.am || die
	# Do not unset user's CFLAGS
	sed -i -e "/^CFLAGS=/s:CFLAGS=\":CFLAGS=\"\$CFLAGS :" configure.ac || die
	eautoreconf
}

src_configure() {
	econf \
		$(use_enable apop) \
		$(use_enable gnutls tls) \
		$(use_enable profile ) \
		$(use_enable sasl)
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS ChangeLog NEWS README TODO
}
