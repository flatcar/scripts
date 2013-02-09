# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libprojectm-qt/libprojectm-qt-2.0.1.ebuild,v 1.4 2012/05/08 07:27:39 nativemad Exp $

EAPI=2
inherit cmake-utils

MY_P=${P/m/M}-Source ; MY_P=${MY_P/lib}

DESCRIPTION="A graphical music visualization plugin similar to milkdrop"
HOMEPAGE="http://projectm.sourceforge.net"
SRC_URI="mirror://sourceforge/projectm/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="debug"

RDEPEND=">=media-libs/libprojectm-2.0.1
	x11-libs/qt-core:4
	x11-libs/qt-gui:4
	x11-libs/qt-opengl:4"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

S=${WORKDIR}/${MY_P}
