# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/dbus-c++/dbus-c++-0.6.0_p20111126.ebuild,v 1.4 2012/05/04 18:35:55 jdhore Exp $

EAPI="3"

inherit autotools

DESCRIPTION="dbus-c++ attempts to provide a C++ API for D-BUS."
HOMEPAGE="http://www.freedesktop.org/wiki/Software/dbus-c++"
SRC_URI="http://www.elvanor.net/files/gentoo/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="debug"

RDEPEND="sys-apps/dbus"
DEPEND="${RDEPEND}
	dev-util/cppunit
	virtual/pkgconfig"

src_prepare() {
	eautoreconf
}

src_configure() {
	econf $(use_enable debug ) || die
}

src_compile() {
	emake || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "Install failed"
}
