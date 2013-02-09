# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gexiv2/gexiv2-0.1.0.ebuild,v 1.2 2010/12/21 15:20:10 ssuominen Exp $

EAPI="2"

inherit versionator eutils gnome2

MY_PV=$(get_version_component_range 1-2)

DESCRIPTION="gexiv2 is a GObject-based wrapper around the Exiv2 library."
HOMEPAGE="http://trac.yorba.org/wiki/gexiv2"
SRC_URI="http://www.yorba.org/download/${PN}/${MY_PV}/lib${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND=">=media-gfx/exiv2-0.19
	<media-gfx/exiv2-0.21
	dev-libs/glib:2"
DEPEND="${RDEPEND}"

S="${WORKDIR}/lib${P}"

src_prepare() {
	sed -e "s/libtool/libtool --tag=CC/" -i Makefile
}

src_install() {
	gnome2_src_install
}
