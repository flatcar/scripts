# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libcli/libcli-1.9.4.ebuild,v 1.3 2012/10/20 16:04:28 jdhore Exp $

EAPI="2"
inherit eutils multilib toolchain-funcs

DESCRIPTION="Cisco-style (telnet) command-line interface library"

HOMEPAGE="http://sites.dparrish.com/libcli"
SRC_URI="http://libcli.googlecode.com/files/${P}.tar.gz"
LICENSE="LGPL-2.1"

SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

DEPEND=""
RDEPEND=""

src_prepare() {
	# Support /lib{32,64}
	sed -i 's:$(PREFIX)/lib:$(libdir):g' Makefile || die
	sed -i 's:PREFIX = /usr/local:&\nlibdir = $(PREFIX)/lib:' Makefile || die

	# Make this respect LDFLAGS, bug #334913
	epatch "${FILESDIR}/${PN}-1.9.4-ldflags.patch"
}

src_compile() {
	emake OPTIM="" DEBUG="" CC="$(tc-getCC)" || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" \
		PREFIX=/usr \
		OPTIM="" \
		DEBUG="" \
		libdir="/usr/$(get_libdir)" \
		install || die "emake install failed"

	dobin clitest || die

	dodoc README || die
}
