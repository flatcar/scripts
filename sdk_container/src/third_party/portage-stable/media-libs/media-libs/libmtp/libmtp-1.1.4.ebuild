# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libmtp/libmtp-1.1.4.ebuild,v 1.6 2012/12/11 16:29:23 axs Exp $

EAPI=4

inherit autotools eutils udev user toolchain-funcs

if [[ ${PV} == *9999* ]]; then
	EGIT_REPO_URI="git://${PN}.git.sourceforge.net/gitroot/${PN}/${PN}"
	inherit git-2
else
	KEYWORDS="amd64 hppa ppc ppc64 x86"
	SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"
fi

DESCRIPTION="An implementation of Microsoft's Media Transfer Protocol (MTP)."
HOMEPAGE="http://libmtp.sourceforge.net/"

LICENSE="LGPL-2.1"
SLOT="0"
IUSE="+crypt doc examples static-libs"

RDEPEND="virtual/libusb:1
	crypt? ( dev-libs/libgcrypt )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( app-doc/doxygen )"

DOCS="AUTHORS ChangeLog README TODO"

pkg_setup() {
	enewgroup plugdev
}

src_prepare() {
	if [[ ${PV} == *9999* ]]; then
		touch config.rpath # This is from upstream autogen.sh
		eautoreconf
	fi
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_enable doc doxygen) \
		$(use_enable crypt mtpz) \
		--with-udev="$(udev_get_udevdir)" \
		--with-udev-group=plugdev \
		--with-udev-mode=0660
}

src_install() {
	default
	prune_libtool_files

	if use examples; then
		docinto examples
		dodoc examples/*.{c,h,sh}
	fi
}
