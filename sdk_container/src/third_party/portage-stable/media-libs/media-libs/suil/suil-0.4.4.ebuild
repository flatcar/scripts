# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/suil/suil-0.4.4.ebuild,v 1.4 2012/05/05 08:02:27 jdhore Exp $

EAPI=4

inherit base waf-utils

DESCRIPTION="Lightweight C library for loading and wrapping LV2 plugin UIs"
HOMEPAGE="http://drobilla.net/software/suil/"
SRC_URI="http://download.drobilla.net/${P}.tar.bz2"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc gtk qt4"

RDEPEND="|| ( media-libs/lv2 ( >=media-libs/lv2core-6 media-libs/lv2-ui ) )
	gtk? ( x11-libs/gtk+:2 )
	qt4? ( x11-libs/qt-gui:4 )"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	virtual/pkgconfig"

PATCHES=( "${FILESDIR}/ldconfig.patch" )
DOCS=( "AUTHORS" "README" "ChangeLog" )

src_configure() {
	# otherwise automagic
	use gtk || sed -i -e 's/gtk+-2.0/DiSaBlEd/' wscript
	use qt4 || sed -i -e 's/QtGui/DiSaBlEd/' wscript
	waf-utils_src_configure \
		"--mandir=/usr/share/man" \
		"--docdir=/usr/share/doc/${PF}" \
		$(use doc && echo "--docs")
}
