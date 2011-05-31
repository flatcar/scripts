# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-auth/consolekit/consolekit-0.4.4.ebuild,v 1.8 2011/04/23 16:58:35 ssuominen Exp $

EAPI=3
inherit autotools eutils linux-info multilib pam

MY_PN=ConsoleKit
MY_P=${MY_PN}-${PV}

DESCRIPTION="Framework for defining and tracking users, login sessions and seats."
HOMEPAGE="http://www.freedesktop.org/wiki/Software/ConsoleKit"
SRC_URI="http://www.freedesktop.org/software/${MY_PN}/dist/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sh sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux"
IUSE="debug doc kernel_linux pam policykit test"

RDEPEND=">=dev-libs/dbus-glib-0.88
	>=dev-libs/glib-2.20:2
	sys-libs/zlib
	x11-libs/libX11
	pam? ( virtual/pam )
	policykit? ( >=sys-auth/polkit-0.96-r1 )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	dev-libs/libxslt
	doc? ( app-text/xmlto )
	test? ( app-text/docbook-xml-dtd:4.1.2 )"

S=${WORKDIR}/${MY_P}

pkg_setup() {
	# This is required to get login-session-id string with pam_ck_connector.so
	if use pam && use kernel_linux; then
		CONFIG_CHECK="~AUDITSYSCALL"
		linux-info_pkg_setup
	fi
}

src_prepare() {
	epatch \
		"${FILESDIR}"/${PN}-0.2.10-cleanup_console_tags.patch \
		"${FILESDIR}"/${PN}-0.4.0-polkit-automagic.patch \
		"${FILESDIR}"/${PN}-0.4.0-multilib.patch \
		"${FILESDIR}"/${PN}-0.4.1-shutdown-reboot-without-policies.patch

	eautoreconf
}

src_configure() {
	econf \
		XMLTO_FLAGS="--skip-validation" \
		--localstatedir="${EPREFIX}"/var \
		$(use_enable pam pam-module) \
		$(use_enable doc docbook-docs) \
		$(use_enable debug) \
		$(use_enable policykit polkit) \
		--with-dbus-services="${EPREFIX}"/usr/share/dbus-1/services \
		--with-pam-module-dir=$(getpam_mod_dir)
}

src_install() {
	emake \
		DESTDIR="${D}" \
		htmldocdir="${EPREFIX}"/usr/share/doc/${PF}/html \
		install || die

	dodoc AUTHORS ChangeLog HACKING NEWS README TODO

	newinitd "${FILESDIR}"/${PN}-0.1.rc consolekit

	keepdir /usr/$(get_libdir)/ConsoleKit/run-session.d
	keepdir /etc/ConsoleKit/run-session.d
	keepdir /var/run/ConsoleKit
	keepdir /var/log/ConsoleKit

	exeinto /etc/X11/xinit/xinitrc.d
	newexe "${FILESDIR}"/90-consolekit-3 90-consolekit || die

	exeinto /usr/$(get_libdir)/ConsoleKit/run-session.d
	doexe "${FILESDIR}"/pam-foreground-compat.ck || die

	find "${ED}" -name '*.la' -exec rm -f {} +
}

pkg_postinst() {
	ewarn "You need to restart ConsoleKit to get the new features."
	ewarn "This can be done with /etc/init.d/consolekit restart"
	ewarn "but make sure you do this and then restart your session"
	ewarn "otherwise you will get access denied for certain actions"
}
