# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libva-vdpau-driver/libva-vdpau-driver-0.7.3.ebuild,v 1.2 2012/11/24 13:26:06 aballier Exp $

EAPI="2"
inherit autotools eutils

MY_P=vdpau-video-${PV}
DESCRIPTION="VDPAU Backend for Video Acceleration (VA) API"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/vaapi"
SRC_URI="http://www.splitted-desktop.com/~gbeauchesne/vdpau-video/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="debug opengl"

RDEPEND="x11-libs/libva[opengl?]
	opengl? ( virtual/opengl )
	x11-libs/libvdpau
	!x11-libs/vdpau-video"

DEPEND="${DEPEND}
	virtual/pkgconfig"

S=${WORKDIR}/${MY_P}

src_prepare() {
	epatch "${FILESDIR}/${PN}-0.7.4-glext-missing-definition.patch"
	eautoreconf
}

src_configure() {
	econf \
		$(use_enable debug) \
		$(use_enable opengl glx)
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"
	dodoc NEWS README AUTHORS
	find "${D}" -name '*.la' -delete
}
