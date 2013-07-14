# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libusb/libusb-1.0.9.ebuild,v 1.9 2012/11/09 20:09:10 ryao Exp $

EAPI=4

DESCRIPTION="Userspace access to USB devices"
HOMEPAGE="http://libusb.org/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="1"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 -amd64-fbsd -x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
IUSE="debug doc static-libs"

RDEPEND="!dev-libs/libusbx:1"
DEPEND="doc? ( app-doc/doxygen )"

DOCS="AUTHORS NEWS PORTING README THANKS TODO"

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_enable debug debug-log)
}

src_compile() {
	default

	use doc && emake -C doc docs
}

src_install() {
	default

	if use doc; then
		insinto /usr/share/doc/${PF}/examples
		doins examples/*.c

		dohtml doc/html/*
	fi

	rm -f "${ED}"/usr/lib*/lib*.la
}
