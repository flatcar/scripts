# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gluon/gluon-0.70.0.ebuild,v 1.3 2011/10/28 23:53:45 abcd Exp $

EAPI=4

OPENGL_REQUIRED="always"
inherit kde4-base

DESCRIPTION="Gluon is a Free and Open Source framework for creating and distributing games."
HOMEPAGE="http://gluon.tuxfamily.org/"
SRC_URI="http://gluon.gamingfreedom.org/sites/default/files/${P}.tar.gz"

LICENSE="GPL-2"
KEYWORDS="~amd64"
SLOT="4"
IUSE=""

COMMON_DEPEND="
	media-libs/glew
	media-libs/libogg
	media-libs/libsndfile
	media-libs/libvorbis
	media-libs/openal
	virtual/glu
	virtual/opengl
	x11-libs/libXrandr
"
DEPEND="${COMMON_DEPEND}
	dev-cpp/eigen:2
	x11-proto/randrproto
"
RDEPEND="${COMMON_DEPEND}"

S="${WORKDIR}/${PN}-${PN}"

src_prepare() {
	kde4-base_src_prepare

	sed -i '/add_subdirectory(src)/s/^#//' "${S}"/CMakeLists.txt || die "couldn't re-enable main library"
}
