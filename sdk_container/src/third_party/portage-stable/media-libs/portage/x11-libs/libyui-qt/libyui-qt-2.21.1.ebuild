# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libyui-qt/libyui-qt-2.21.1.ebuild,v 1.3 2012/08/03 14:46:48 miska Exp $

EAPI=4

inherit cmake-utils

DESCRIPTION="UI abstraction library - Qt plugin"
HOMEPAGE="http://sourceforge.net/projects/libyui/"
SRC_URI="mirror://sourceforge/libyui/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="x11-libs/qt-gui:4
	x11-libs/libyui
"
RDEPEND="${DEPEND}"

src_install() {
	cmake-utils_src_install
	rm -rf "${ED}/usr/include"
}
