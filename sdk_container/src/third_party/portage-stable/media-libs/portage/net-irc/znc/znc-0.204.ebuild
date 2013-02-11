# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/znc/znc-0.204.ebuild,v 1.2 2012/05/03 06:27:13 jdhore Exp $

EAPI=4

PYTHON_DEPEND="python? 3"
inherit base python

DESCRIPTION="An advanced IRC Bouncer"
HOMEPAGE="http://znc.sourceforge.net"
SRC_URI="http://znc.in/releases/archive/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="ares debug extras ipv6 perl python ssl sasl tcl"

RDEPEND="
	ares? ( >=net-dns/c-ares-1.5 )
	perl? ( >=dev-lang/perl-5.10 )
	sasl? ( >=dev-libs/cyrus-sasl-2 )
	ssl? ( >=dev-libs/openssl-0.9.7d )
	tcl? ( dev-lang/tcl )
"
DEPEND="
	virtual/pkgconfig
	perl? ( dev-lang/swig )
	python? (
		>=dev-lang/swig-2.0.2
		>=dev-lang/perl-5.10
	)
	${RDEPEND}
"

pkg_setup() {
	if use python; then
		python_set_active_version 3
		python_pkg_setup
	fi
}

src_configure() {
	econf \
		$(use_enable ares c-ares) \
		$(use_enable debug) \
		$(use_enable extras extra) \
		$(use_enable ipv6) \
		$(use_enable perl) \
		$(use python && echo "--enable-python=python-$(python_get_version)") \
		$(use_enable sasl) \
		$(use_enable ssl openssl) \
		$(use_enable tcl tcl)
}

src_install() {
	emake install DESTDIR="${D}"
	dodoc AUTHORS README.md
}

pkg_postinst() {
	elog
	elog "Run 'znc --makeconf' as the user you want to run ZNC as"
	elog "to make a configuration file"
	elog "If you are using SSL you should also run 'znc --makepem'"
	elog
}
