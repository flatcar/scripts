# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/wepattack/wepattack-0.1.3-r3.ebuild,v 1.3 2006/11/25 08:30:06 blubb Exp $

inherit eutils toolchain-funcs

MY_P="WepAttack-${PV}"
DESCRIPTION="WLAN tool for breaking 802.11 WEP keys"
HOMEPAGE="http://wepattack.sourceforge.net/"
SRC_URI="mirror://sourceforge/wepattack/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="john"

DEPEND="sys-libs/zlib
	net-libs/libpcap
	dev-libs/openssl"

RDEPEND="${DEPEND}
	john? ( app-crypt/johntheripper )"

S="${WORKDIR}/${MY_P}"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PV}-filter-mac-address.patch
	epatch "${FILESDIR}"/${P}-missed-string.h-warnings-fix.diff
	chmod +x src/wlan
	sed -i \
		-e "/^CFLAGS=/s:=:=${CFLAGS} :" \
		-e 's:-fno-for-scope::g' \
		-e "/^CC=/s:gcc:$(tc-getCC):" \
		-e "/^LD=/s:gcc:$(tc-getCC):" \
		-e 's:log.o\\:log.o \\:' \
		src/Makefile || die "sed Makefile failed"
	sed -i \
		-e "s/wordfile:/-wordlist=/" \
		run/wepattack_word || die "sed wepattack_world faild"
}

src_compile() {
	cd src
	emake || die "emake failed"
}

src_install() {
	dobin src/wepattack || die "dobin failed"
	if use john; then
		dosbin run/wepattack_{inc,word} || die "dosbin failed"
		insinto /etc
		doins "${FILESDIR}"/wepattack.conf
	fi
	dodoc README
}
