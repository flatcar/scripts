# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libvdpau/libvdpau-0.4.1-r1.ebuild,v 1.4 2012/05/16 15:22:35 aballier Exp $

EAPI=4
inherit multilib

DESCRIPTION="VDPAU wrapper and trace libraries"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/VDPAU"
SRC_URI="http://people.freedesktop.org/~aplattner/vdpau/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 x86 ~amd64-fbsd ~x86-fbsd"
IUSE="doc"

#unfortunately, there's driver versions in between that this works with
RDEPEND="x11-libs/libX11
	x11-libs/libXext
	!=x11-drivers/nvidia-drivers-180*
	!=x11-drivers/nvidia-drivers-185*
	!=x11-drivers/nvidia-drivers-190.18
	!=x11-drivers/nvidia-drivers-190.25
	!=x11-drivers/nvidia-drivers-190.32
	!=x11-drivers/nvidia-drivers-190.36
	!=x11-drivers/nvidia-drivers-190.40"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	>=x11-proto/dri2proto-2.2
	doc? (
		app-doc/doxygen
		media-gfx/graphviz
		virtual/latex-base
	)"

DOCS="AUTHORS ChangeLog"

src_configure() {
	econf \
		--docdir="${EPREFIX}/usr/share/doc/${PF}" \
		--disable-dependency-tracking \
		$(use_enable doc documentation) \
		--with-module-dir="${EPREFIX}/usr/$(get_libdir)/vdpau"
}

src_install() {
	default
	find "${ED}" -name '*.la' -exec rm -f '{}' +
}
