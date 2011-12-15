# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/socat/socat-1.7.1.3.ebuild,v 1.7 2011/12/15 19:33:19 vapier Exp $

EAPI="2"

inherit eutils flag-o-matic autotools

DESCRIPTION="Multipurpose relay (SOcket CAT)"
HOMEPAGE="http://www.dest-unreach.org/socat/"
MY_P=${P/_beta/-b}
S="${WORKDIR}/${MY_P}"
SRC_URI="http://www.dest-unreach.org/socat/download/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc sparc x86 ~ppc-macos"
IUSE="ssl readline ipv6 tcpd"

DEPEND="
	ssl? ( >=dev-libs/openssl-0.9.6 )
	readline? ( >=sys-libs/ncurses-5.1 >=sys-libs/readline-4.1 )
	tcpd? ( sys-apps/tcp-wrappers )
"
RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/${P}-cross-compile.patch
	eautoreconf
}

src_configure() {
	filter-flags -Wno-error*
	econf \
		$(use_enable ssl openssl) \
		$(use_enable readline) \
		$(use_enable ipv6 ip6) \
		$(use_enable tcpd libwrap)
}

src_test() {
	TMPDIR="${T}" emake test || die 'self test failed'
}

src_install() {
	emake install DESTDIR="${D}" || die "emake install failed"

	dodoc BUGREPORTS CHANGES DEVELOPMENT \
		FAQ FILES PORTING README SECURITY VERSION
	docinto examples
	dodoc EXAMPLES *.sh
	dohtml doc/*.html doc/*.css
}
