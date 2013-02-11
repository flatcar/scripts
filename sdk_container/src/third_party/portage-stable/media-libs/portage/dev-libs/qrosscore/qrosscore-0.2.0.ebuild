# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/qrosscore/qrosscore-0.2.0.ebuild,v 1.3 2012/07/19 15:43:32 kensington Exp $

EAPI=3

inherit cmake-utils

DESCRIPTION="KDE-free version of Kross (core libraries and Qt Script backend)"
HOMEPAGE="http://github.com/0xd34df00d/Qross"
SRC_URI="mirror://github/0xd34df00d/Qross/qross-${PV}.tar.bz2"
S="${WORKDIR}/qross-${PV}/src/qross"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug"

DEPEND="x11-libs/qt-core:4
		x11-libs/qt-gui:4
		x11-libs/qt-script:4"
RDEPEND="${DEPEND}"
