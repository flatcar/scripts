# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/serdisplib/serdisplib-1.97.5.ebuild,v 1.8 2012/05/25 08:28:21 ssuominen Exp $

EAPI=1

inherit eutils

DESCRIPTION="Library to drive serial/parallel/usb displays with built-in controllers"
HOMEPAGE="http://serdisplib.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE="usb"

DEPEND="media-libs/gd
	usb? ( virtual/libusb:0 )"
RDEPEND="${DEPEND}"

pkg_setup() {
	if ! built_with_use -a media-libs/gd jpeg png; then
		echo
		eerror "Please rebuild media-libs/gd with USE=\"jpeg png\"."
		die "Please rebuild media-libs/gd with USE=\"jpeg png\"."
	fi
}

src_compile() {
	econf \
		--prefix="${D}/usr" \
		$(use_enable usb libusb) \
		|| die "configure failed"
	emake || die "make failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"

	dodoc AUTHORS HISTORY README
}
