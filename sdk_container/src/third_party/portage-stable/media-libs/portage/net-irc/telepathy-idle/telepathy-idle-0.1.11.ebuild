# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/telepathy-idle/telepathy-idle-0.1.11.ebuild,v 1.7 2012/05/03 06:27:14 jdhore Exp $

EAPI="4"
PYTHON_DEPEND="2"

inherit python

DESCRIPTION="Full-featured IRC connection manager for Telepathy."
HOMEPAGE="http://telepathy.freedesktop.org/wiki/Components"
SRC_URI="http://telepathy.freedesktop.org/releases/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm ia64 ppc ~ppc64 sparc x86 ~x86-linux"
IUSE="test"

RDEPEND="dev-libs/dbus-glib
	>=dev-libs/glib-2.28.0:2
	>=dev-libs/openssl-0.9.7
	>=net-libs/telepathy-glib-0.15.9
	sys-apps/dbus"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	test? ( dev-python/twisted-words )"

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup
}

src_prepare() {
	python_convert_shebangs -r 2 .
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS NEWS
}
