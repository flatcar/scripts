# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/aircrack-ng/aircrack-ng-1.1-r2.ebuild,v 1.5 2012/12/23 18:15:03 maekke Exp $

EAPI="3"

inherit eutils toolchain-funcs versionator

MY_PV="$(replace_version_separator 2 '-')"

DESCRIPTION="WLAN tools for breaking 802.11 WEP/WPA keys"
HOMEPAGE="http://www.aircrack-ng.org"
SRC_URI="http://download.aircrack-ng.org/${PN}-${MY_PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ppc x86 ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE="+sqlite kernel_linux kernel_FreeBSD"

DEPEND="dev-libs/openssl
	sqlite? ( >=dev-db/sqlite-3.4 )"
RDEPEND="${DEPEND}
	kernel_linux? ( net-wireless/iw net-wireless/wireless-tools )"

S="${WORKDIR}/${PN}-${MY_PV}"

have_sqlite() {
	use sqlite && echo "true" || echo "false"
}

src_prepare() {
	epatch "${FILESDIR}/${P}-respect_LDFLAGS.patch"
	epatch "${FILESDIR}/${PN}-1.0_rc4-fix_build.patch"
	epatch "${FILESDIR}/${P}-parallelmake.patch"
	epatch "${FILESDIR}/${P}-sse-pic.patch"
	epatch "${FILESDIR}/${P}-CVE-2010-1159.patch"
}

src_compile() {
	# UNSTABLE=true enables building of buddy-ng, easside-ng, tkiptun-ng and wesside-ng
	emake CC="$(tc-getCC)" LD="$(tc-getLD)" sqlite="$(have_sqlite)" UNSTABLE=true || die "emake failed"
}

src_install() {
	# UNSTABLE=true enables installation of buddy-ng, easside-ng, tkiptun-ng and wesside-ng
	emake \
		prefix="${EPREFIX}/usr" \
		mandir="${EPREFIX}/usr/share/man/man1" \
		DESTDIR="${D}" \
		sqlite="$(have_sqlite)" \
		UNSTABLE=true \
		install \
		|| die "emake install failed"

	dodoc AUTHORS ChangeLog README
}

pkg_postinst() {
	# Message is (c) FreeBSD
	# http://www.freebsd.org/cgi/cvsweb.cgi/ports/net-mgmt/aircrack-ng/files/pkg-message.in?rev=1.5
	if use kernel_FreeBSD ; then
		einfo "Contrary to Linux, it is not necessary to use airmon-ng to enable the monitor"
		einfo "mode of your wireless card.  So do not care about what the manpages say about"
		einfo "airmon-ng, airodump-ng sets monitor mode automatically."
		echo
		einfo "To return from monitor mode, issue the following command:"
		einfo "    ifconfig \${INTERFACE} -mediaopt monitor"
		einfo
		einfo "For aireplay-ng you need FreeBSD >= 7.0."
	fi
}
