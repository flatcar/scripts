# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libgxim/libgxim-0.3.3.ebuild,v 1.3 2012/05/05 03:52:24 jdhore Exp $

EAPI=3

DESCRIPTION="GObject-based XIM protocol library"
HOMEPAGE="http://code.google.com/p/libgxim/"
SRC_URI="http://libgxim.googlecode.com/files/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc static-libs"

RDEPEND=">=dev-libs/check-0.9.4
	>=dev-libs/dbus-glib-0.74
	>=dev-libs/glib-2.16
	>=sys-apps/dbus-0.23"
DEPEND="${RDEPEND}
	dev-lang/ruby
	virtual/pkgconfig
	doc? ( >=dev-util/gtk-doc-1.8 )"

src_configure() {
	econf $(use_enable static-libs static) || die
}

src_install() {
	emake DESTDIR="${D}" install || die

	dodoc AUTHORS ChangeLog NEWS README || die
}
