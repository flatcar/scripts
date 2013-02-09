# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gluon/gluon-0.71.0.ebuild,v 1.1 2012/06/24 17:13:48 kensington Exp $

EAPI=4

OPENGL_REQUIRED="always"
inherit kde4-base versionator

DESCRIPTION="Gluon is a Free and Open Source framework for creating and distributing games."
HOMEPAGE="http://gluon.tuxfamily.org/"
SRC_URI="mirror://kde/unstable/${PN}/$(get_version_component_range 1-2)/src/${P}.tar.gz"

LICENSE="LGPL-2.1"
KEYWORDS="~amd64"
SLOT="4"
IUSE="debug examples"

DEPEND="
	media-libs/alure
	media-libs/libsndfile
	media-libs/openal
	virtual/glu
	virtual/opengl
	x11-libs/qt-declarative:4
"
RDEPEND="${DEPEND}"

PATCHES=( "${FILESDIR}/${P}-gcc-4.7.patch" )

src_configure() {
	local mycmakeargs=(
		$(cmake-utils_use examples INSTALL_EXAMPLES)
	)

	kde4-base_src_configure
}
