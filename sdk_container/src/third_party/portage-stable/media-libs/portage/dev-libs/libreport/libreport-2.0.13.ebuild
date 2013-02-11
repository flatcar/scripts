# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libreport/libreport-2.0.13.ebuild,v 1.1 2012/09/22 20:12:48 tetromino Exp $

EAPI="4"
PYTHON_DEPEND="2:2.6"

inherit autotools eutils python user

DESCRIPTION="Generic library for reporting software bugs"
HOMEPAGE="https://fedorahosted.org/abrt/"
SRC_URI="https://fedorahosted.org/released/abrt/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug"

COMMON_DEPEND=">=dev-libs/btparser-0.18
	>=dev-libs/glib-2.21:2
	dev-libs/json-c
	dev-libs/libtar
	dev-libs/libxml2:2
	dev-libs/newt
	dev-libs/nss
	dev-libs/xmlrpc-c
	net-libs/libproxy
	net-misc/curl[ssl]
	sys-apps/dbus
	>=x11-libs/gtk+-3.3.12:3
	x11-misc/xdg-utils"
RDEPEND="${COMMON_DEPEND}
	|| ( gnome-base/gnome-keyring >=kde-base/kwalletd-4.8 )"
DEPEND="${COMMON_DEPEND}
	app-text/asciidoc
	app-text/xmlto
	>=dev-util/intltool-0.3.50
	>=sys-devel/gettext-0.17
	virtual/pkgconfig"

# Tests require python-meh, which is highly redhat-specific.
RESTRICT="test"

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup

	enewgroup abrt
	enewuser abrt -1 -1 -1 abrt
}

src_prepare() {
	# Replace redhat- and fedora-specific defaults with gentoo ones, and disable
	# code that requires gentoo infra support.
	epatch "${FILESDIR}/${PN}-2.0.13-gentoo.patch"

	# Modify uploader_event so that the gui recognizes it
	epatch "${FILESDIR}/${PN}-2.0.7-uploader_event-syntax.patch"

	# automake-1.12
	epatch "${FILESDIR}/${PN}-2.0.13-automake-1.12.patch"

	python_clean_py-compile_files

	mkdir -p m4
	eautoreconf
}

src_configure() {
	ECONF="--disable-bodhi
		--localstatedir=${EPREFIX}/var"
	# --disable-debug enables debug!
	use debug && ECONF="${ECONF} --enable-debug"
	econf ${ECONF}
}

src_install() {
	default

	# Need to set correct ownership for use by app-admin/abrt
	diropts -o abrt -g abrt
	keepdir /var/spool/abrt

	find "${D}" -name '*.la' -exec rm -f {} + || die
}

pkg_postinst() {
	python_mod_optimize report reportclient
}

pkg_postrm() {
	python_mod_cleanup report reportclient
}
