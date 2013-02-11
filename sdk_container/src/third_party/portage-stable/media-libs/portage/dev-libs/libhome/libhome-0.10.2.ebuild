# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libhome/libhome-0.10.2.ebuild,v 1.3 2011/01/10 19:50:30 flameeyes Exp $

inherit autotools db-use eutils

DESCRIPTION="libhome is a library providing a getpwnam() emulation"
HOMEPAGE="http://pll.sourceforge.net"
SRC_URI="mirror://sourceforge/pll/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="berkdb ldap mysql pam postgres"

DEPEND="berkdb? ( >=sys-libs/db-4 )
	ldap? ( net-nds/openldap )
	mysql? ( virtual/mysql )
	pam? ( virtual/pam )
	postgres? ( dev-db/postgresql-server )"
RDEPEND="${DEPEND}"

src_unpack() {
	unpack ${A}
	cd "${S}"
	rm -f aclocal.m4

	epatch "${FILESDIR}"/${PN}-0.10.2-Makefile.patch
	epatch "${FILESDIR}"/${PN}-0.10.2-ldap_deprecated.patch

	# bug 225579
	sed -i -e 's:\<VERSION\>:__PKG_VERSION:' configure.in

	sed -i -e '/AC_SEARCH_LIBS.*db4/s: db-4.* db4:'$(db_libname)':' \
		configure.in

	eautoreconf
}

src_compile() {
	econf --without-db3 \
		$(use_with berkdb db4 $(db_includedir)) \
		$(use_with ldap) \
		$(use_with mysql) \
		$(use_with pam) \
		$(use_with postgres pgsql) \
	|| die "econf failed"
	emake || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"
}
