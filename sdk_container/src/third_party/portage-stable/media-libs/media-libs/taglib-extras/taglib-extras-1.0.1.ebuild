# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/taglib-extras/taglib-extras-1.0.1.ebuild,v 1.6 2011/01/18 22:31:26 ranger Exp $

EAPI=2
inherit cmake-utils

DESCRIPTION="Unofficial taglib plugins maintained by the Amarok team"
HOMEPAGE="http://developer.kde.org/~wheeler/taglib.html"
SRC_URI="http://www.kollide.net/~jefferai/${P}.tar.gz"

LICENSE="GPL-2"
KEYWORDS="amd64 ppc ~ppc64 x86"
SLOT="0"
IUSE="debug"

TAGLIB_VERSION="1.6"
RDEPEND="
	>=media-libs/taglib-${TAGLIB_VERSION}
"
DEPEND="${RDEPEND}"

DOCS="AUTHORS ChangeLog"
