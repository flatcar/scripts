# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/qrosscore/qrosscore-9999.ebuild,v 1.2 2012/07/19 15:43:32 kensington Exp $

EAPI=3

EGIT_REPO_URI="git://github.com/0xd34df00d/Qross.git"
EGIT_PROJECT="qross"

inherit cmake-utils git-2

DESCRIPTION="KDE-free version of Kross (core libraries and Qt Script backend)."
HOMEPAGE="http://github.com/0xd34df00d/Qross"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="debug"

DEPEND="x11-libs/qt-core:4
		x11-libs/qt-gui:4
		x11-libs/qt-script:4"
RDEPEND="${DEPEND}"

CMAKE_USE_DIR="${S}/src/qross"
