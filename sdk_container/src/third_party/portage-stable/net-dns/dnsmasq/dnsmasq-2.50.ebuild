# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-dns/dnsmasq/dnsmasq-2.50.ebuild,v 1.8 2009/09/20 18:53:48 nixnut Exp $

EAPI=2

inherit eutils toolchain-funcs flag-o-matic

MY_P="${P/_/}"
MY_PV="${PV/_/}"
DESCRIPTION="Small forwarding DNS server"
HOMEPAGE="http://www.thekelleys.org.uk/dnsmasq/"
SRC_URI="http://www.thekelleys.org.uk/dnsmasq/${MY_P}.tar.lzma"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="dbus +dhcp ipv6 nls tftp"

RDEPEND="dbus? ( sys-apps/dbus )
	nls? ( sys-devel/gettext )"

DEPEND="${RDEPEND}
	|| ( app-arch/xz-utils app-arch/lzma-utils )"

S="${WORKDIR}/${PN}-${MY_PV}"

src_prepare() {
	sed -i '/^AWK/s:nawk:gawk:' Makefile #214865

	# dnsmasq on FreeBSD wants the config file in a silly location, this fixes
	epatch "${FILESDIR}/${PN}-2.47-fbsd-config.patch"
}

src_configure() {
	use tftp || append-flags -DNO_TFTP
	use dhcp || append-flags -DNO_DHCP
	use ipv6 || append-flags -DNO_IPV6
	use dbus && sed -i '$ a #define HAVE_DBUS' src/config.h
}

src_compile() {
	emake \
		PREFIX=/usr \
		CC="$(tc-getCC)" \
		CFLAGS="${CFLAGS}" \
		all$(use nls && echo "-i18n") || die
}

src_install() {
	emake \
		PREFIX=/usr \
		MANDIR=/usr/share/man \
		DESTDIR="${D}" \
		install$(use nls && echo "-i18n") || die

	dodoc CHANGELOG FAQ
	dohtml *.html

	newinitd "${FILESDIR}"/dnsmasq-init dnsmasq
	newconfd "${FILESDIR}"/dnsmasq.confd dnsmasq
	insinto /etc
	newins dnsmasq.conf.example dnsmasq.conf

	if use dbus ; then
		insinto /etc/dbus-1/system.d
		doins dbus/dnsmasq.conf
	fi
}
