# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/fxscintilla/fxscintilla-2.28.0.ebuild,v 1.3 2012/08/13 16:07:07 mabi Exp $

EAPI=4

inherit autotools eutils multilib

DESCRIPTION="A free source code editing component for the FOX-Toolkit"
HOMEPAGE="http://www.nongnu.org/fxscintilla/"
SRC_URI="http://savannah.nongnu.org/download/fxscintilla/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~hppa ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
IUSE="doc"

RDEPEND="|| ( x11-libs/fox:1.6 x11-libs/fox:1.7 )"
DEPEND="${RDEPEND}"

src_prepare() {
	# fox-1.7.32 installs fox17.pc, the fox module is used by fox-1.6
	if has_version "x11-libs/fox:1.7" ; then
		sed -i -e "s/fox >= 1.7/fox17 >= 1.7/" "${S}/configure.in"
		eautoreconf
	fi
}

src_configure() {
	econf --libdir=/usr/$(get_libdir) --enable-shared
}

src_install () {
	emake DESTDIR="${D}" install

	dodoc README ChangeLog
	use doc && dohtml doc/*
}

pkg_postinst() {
	elog "FXScintilla is now built only against the highest available"
	elog "FOX-version you have installed."
}
