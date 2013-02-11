# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/xchatosd/xchatosd-5.19.ebuild,v 1.7 2009/02/12 05:17:54 dirtyepic Exp $

inherit toolchain-funcs flag-o-matic

DESCRIPTION="On-Screen Display for XChat"
HOMEPAGE="http://sourceforge.net/projects/xchatosd/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ia64 ~ppc x86"
IUSE="iconv"

RDEPEND=">=x11-libs/xosd-2.2.5
	>=net-irc/xchat-2.0.9"
DEPEND="${RDEPEND}
	>=sys-apps/sed-4"

src_unpack() {
	unpack ${A}

	# We have our own include file in /usr/include/xchat
	einfo "Updating xchat-plugin.h from /usr/include/xchat/xchat-plugin.h"
	cp -f /usr/include/xchat/xchat-plugin.h "${S}"/xchat-plugin.h
	epatch "${FILESDIR}/${P}-gcc4.patch"
	epatch "${FILESDIR}"/${P}-gcc43.patch
}

src_compile() {
	append-flags -fPIC -DPIC
	use iconv || sed -i -e "/^#define ICONV_LIB$/d" xchatosd.h

	emake CC="$(tc-getCXX)" CPP="$(tc-getCXX)" CFLAGS="${CFLAGS}" || die "emake failed"
}

src_install() {
	exeinto /usr/$(get_libdir)/xchat/plugins
	doexe xchatosd.so || die "doexe failed"
	dodoc ChangeLog README || die "dodoc failed"
}
