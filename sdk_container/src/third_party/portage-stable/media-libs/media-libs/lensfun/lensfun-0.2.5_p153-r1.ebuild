# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/lensfun/lensfun-0.2.5_p153-r1.ebuild,v 1.2 2012/05/29 16:39:52 aballier Exp $

EAPI=4
inherit python multilib cmake-utils

DESCRIPTION="lensfun: A library for rectifying and simulating photographic lens distortions"
HOMEPAGE="http://lensfun.berlios.de/"
SRC_URI="http://dev.gentoo.org/~dilfridge/distfiles/${P}.tar.xz"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-fbsd"
IUSE="doc"

RDEPEND=">=dev-libs/glib-2
	>=media-libs/libpng-1.2"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )"

PATCHES=(
	"${FILESDIR}/${P}-build.patch"
	"${FILESDIR}/${P}-pc.patch"
)

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup
}

src_configure() {
	mycmakeargs=(
		$(cmake-utils_use_build doc)
		-DLIBDIR=$(get_libdir)
		-DDOCDIR=/usr/share/doc/${P}
	)
	cmake-utils_src_configure
}
