# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libusb/libusb-1.0.8.ebuild,v 1.11 2011/09/28 13:03:27 ssuominen Exp $

EAPI="2"

DESCRIPTION="Userspace access to USB devices"
HOMEPAGE="http://libusb.org/"
SRC_URI="mirror://sourceforge/libusb/${P}.tar.bz2"
LICENSE="LGPL-2.1"
SLOT="1"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 -x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
IUSE="debug doc static-libs"

DEPEND="doc? ( app-doc/doxygen )"
RDEPEND=""

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_enable debug debug-log)
}

src_compile() {
	default

	if use doc ; then
		cd doc
		emake docs || die "making docs failed"
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc AUTHORS ChangeLog NEWS PORTING README THANKS TODO

	if use doc ; then
		insinto /usr/share/doc/${PF}/examples
		doins examples/*.c

		dohtml doc/html/*
	fi

	rm -f "${D}"/usr/lib*/libusb*.la
}
