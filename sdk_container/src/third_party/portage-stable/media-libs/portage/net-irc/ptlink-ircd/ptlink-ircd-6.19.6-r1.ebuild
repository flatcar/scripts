# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/ptlink-ircd/ptlink-ircd-6.19.6-r1.ebuild,v 1.2 2009/06/06 14:58:30 ssuominen Exp $

inherit eutils ssl-cert

MY_P="PTlink${PV}"

DESCRIPTION="PTlink IRCd is a secure IRC daemon with many advanced features."
HOMEPAGE="http://www.ptlink.net/"
SRC_URI="ftp://ftp.sunsite.dk/projects/ptlink/ircd/${MY_P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~ppc ~sparc ~x86"

IUSE="ssl"
DEPEND="sys-libs/zlib
	ssl? ( dev-libs/openssl )"

S=${WORKDIR}/${MY_P}

src_unpack() {
	unpack ${A}
	find "${S}" -type d -name CVS -print0 2>/dev/null | xargs -0r rm -rf
}

src_compile() {
	econf \
		--disable-ipv6 \
		$(use_with ssl ssl openssl) \
		|| die "econf failed"
	emake CFLAGS="${CFLAGS}" || die "emake failed"
}

src_install() {
	newbin src/ircd ptlink-ircd || die "newbin failed"
	newbin tools/fixklines ptlink-ircd-fixklines || die "newbin failed"
	newbin tools/mkpasswd ptlink-ircd-mkpasswd || die "newbin failed"

	insinto /etc/ptlink-ircd
	fperms 700 /etc/ptlink-ircd || die "fperms failed"
	doins samples/{kline.conf,{opers,ptlink}.motd,help.{admin,oper,user}} || die "newins failed"
	newins samples/example.conf.short ircd.conf || die "newins failed"
	newins samples/example.conf.trillian ircd.conf.trillian || die "newins failed"
	newins samples/main.dconf.sample main.dconf || die "newins failed"
	newins samples/network.dconf.sample network.dconf || die "newins failed"

	insinto /usr/share/ptlink-ircd/codepage
	doins src/codepage/*.enc || die "doins failed"
	dosym /usr/share/ptlink-ircd/codepage /etc/ptlink-ircd/codepage || die "dosym failed"

	rm -rf doc/old
	dodoc doc/* doc_hybrid6/* ircdcron/* CHANGES README || die "dodoc failed"

	keepdir /var/log/ptlink-ircd /var/lib/ptlink-ircd || die "keepdir failed"
	dosym /var/log/ptlink-ircd /var/lib/ptlink-ircd/log || die "dosym failed"

	newinitd "${FILESDIR}/ptlink-ircd.initd" ptlink-ircd || die "newinitd failed"
	newconfd "${FILESDIR}/ptlink-ircd.confd" ptlink-ircd || die "newconfd failed"
}

pkg_postinst() {
	# Move docert from src_install() to install_cert for bug #201678
	use ssl && (
		if [[ ! -f "${ROOT}"/etc/ptlink-ircd/server.key.pem ]]; then
			install_cert /etc/ptlink-ircd/server || die "install_cert failed"
			mv "${ROOT}"/etc/ptlink-ircd/server.crt	"${ROOT}"/etc/ptlink-ircd/server.cert.pem
			mv "${ROOT}"/etc/ptlink-ircd/server.csr "${ROOT}"/etc/ptlink-ircd/server.req.pem
			mv "${ROOT}"/etc/ptlink-ircd/server.key "${ROOT}"/etc/ptlink-ircd/server.key.pem
		fi
	)

	enewuser ptlink-ircd

	chown ptlink-ircd \
		"${ROOT}"/{etc,var/{log,lib}}/ptlink-ircd \
		"${ROOT}"/etc/ptlink-ircd/server.key.pem

	elog
	elog "PTlink IRCd will run without configuration, although this is strongly"
	elog "advised against."
	elog
	elog "You can find example cron script ircd.cron here:"
	elog "   /usr/share/doc/${PF}"
	elog
	elog "You can also use /etc/init.d/ptlink-ircd to start at boot"
	elog
}
