# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/bobotpp/bobotpp-2.2.2.ebuild,v 1.7 2010/12/03 00:40:33 flameeyes Exp $

inherit autotools eutils

DESCRIPTION="A flexible IRC bot scriptable in scheme"
HOMEPAGE="http://unknownlamer.org/code/bobot.html"
SRC_URI="http://savannah.nongnu.org/download/${PN}/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="ppc x86 ~amd64"
IUSE="guile"

DEPEND="guile? ( dev-scheme/guile )"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/bobotpp-2.2.2-gcc43.patch \
		"${FILESDIR}"/${P}-asneeded.patch
	eautoreconf
}

src_compile() {
	econf $(use_enable guile scripting) || die "econf failed"
	emake || die "emake failed"
}

src_install() {
	make DESTDIR="${D}" install || die "install failed"

	dosym bobot++.info /usr/share/info/bobotpp.info || die "dosym failed"

	dodoc AUTHORS ChangeLog NEWS README SCRIPTING TODO || die "dodoc failed"
	dohtml doc/index.html || die "dohtml failed"

	docinto example-config
	dodoc examples/{bot.*,scripts.load} || die "dodoc failed"

	docinto example-scripts
	dodoc scripts/{boulet,country,eval,hello,log.scm,tamere,uname,uptime} || die "dodoc failed"
}

pkg_postinst() {
	elog
	elog "You can find a sample configuration file set in"
	elog "/usr/share/doc/${PF}/example-config"
	elog
}
