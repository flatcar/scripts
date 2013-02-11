# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libvdpau/libvdpau-0.5.ebuild,v 1.4 2012/11/22 10:06:42 ago Exp $

EAPI=4
inherit eutils libtool

DESCRIPTION="VDPAU wrapper and trace libraries"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/VDPAU"
SRC_URI="http://people.freedesktop.org/~aplattner/vdpau/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 x86 ~amd64-fbsd ~x86-fbsd"
IUSE="doc dri"

RDEPEND="x11-libs/libX11
	dri? ( x11-libs/libXext )
	!=x11-drivers/nvidia-drivers-180*
	!=x11-drivers/nvidia-drivers-185*
	!=x11-drivers/nvidia-drivers-190*"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? (
		app-doc/doxygen
		media-gfx/graphviz
		virtual/latex-base
		)
	dri? ( >=x11-proto/dri2proto-2.2 )"

DOCS="AUTHORS ChangeLog"

src_prepare() {
	elibtoolize
}

src_configure() {
	econf \
		--docdir="${EPREFIX}"/usr/share/doc/${PF} \
		$(use_enable doc documentation) \
		$(use dri || echo --disable-dri2)
}

src_install() {
	default
	prune_libtool_files --all
}
