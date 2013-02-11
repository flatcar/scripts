# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/startup-notification/startup-notification-0.10.ebuild,v 1.14 2012/05/05 03:52:26 jdhore Exp $

EAPI=4
inherit autotools eutils

DESCRIPTION="Application startup notification and feedback library"
HOMEPAGE="http://www.freedesktop.org/software/startup-notification"
SRC_URI="http://freedesktop.org/software/${PN}/releases/${P}.tar.gz"

LICENSE="LGPL-2 MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

RDEPEND="x11-libs/libX11
	x11-libs/libSM
	x11-libs/libICE
	x11-libs/libxcb
	<x11-libs/xcb-util-0.3.8
	>=x11-libs/xcb-util-0.3"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	x11-proto/xproto
	x11-libs/libXt"

DOCS="AUTHORS ChangeLog doc/startup-notification.txt NEWS README"

src_prepare() {
	# Do not build tests unless required
	epatch "${FILESDIR}"/${P}-tests.patch
	eautoreconf
}

src_configure() {
	econf --disable-static
}

src_install() {
	default
	rm -f "${ED}"/usr/lib*/libstartup-notification-1.la
}
