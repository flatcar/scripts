# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libechonest/libechonest-1.2.1.ebuild,v 1.5 2012/12/27 23:14:16 hasufell Exp $

EAPI=4
inherit cmake-utils

DESCRIPTION="A library for communicating with The Echo Nest"
HOMEPAGE="http://projects.kde.org/projects/playground/libs/libechonest"
SRC_URI="http://pwsp.cleinias.com/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND=">=dev-libs/qjson-0.5
	x11-libs/qt-core:4"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	x11-libs/qt-test:4"

RESTRICT="test" # network access required

DOCS=( AUTHORS README TODO )
PATCHES=( "${FILESDIR}"/${P}-Werror.patch )
