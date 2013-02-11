# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/mdk/mdk-3.6.ebuild,v 1.1 2011/02/22 18:48:52 c1pher Exp $

EAPI="3"
inherit eutils toolchain-funcs

MY_P="${PN}${PV/./-v}"
DESCRIPTION="Wireless injection tool with various functions."
HOMEPAGE="http://homepages.tu-darmstadt.de/~p_larbig/wlan"
SRC_URI="${HOMEPAGE}/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="net-wireless/aircrack-ng"
S="${WORKDIR}/${MY_P}"

src_prepare() {
	epatch "${FILESDIR}"/${PV}-makefile.patch
}

src_compile() {
	emake CC=$(tc-getCC) || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "Install failed."

	insinto /usr/share/${PN}
	doins -r useful_files || die

	dohtml docs/* || die
	dodoc AUTHORS CHANGELOG TODO || die
}
