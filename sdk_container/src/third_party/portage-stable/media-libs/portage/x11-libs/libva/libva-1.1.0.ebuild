# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libva/libva-1.1.0.ebuild,v 1.6 2012/11/21 18:13:30 aballier Exp $

EAPI=4

SCM=""
if [ "${PV%9999}" != "${PV}" ] ; then # Live ebuild
	SCM=git-2
	EGIT_BRANCH=master
	EGIT_REPO_URI="git://anongit.freedesktop.org/vaapi/libva"
fi

inherit autotools ${SCM} multilib

DESCRIPTION="Video Acceleration (VA) API for Linux"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/vaapi"
if [ "${PV%9999}" != "${PV}" ] ; then # Live ebuild
	SRC_URI=""
	S="${WORKDIR}/${PN}"
else
	SRC_URI="http://cgit.freedesktop.org/vaapi/libva/snapshot/${P}.tar.bz2"
fi

LICENSE="MIT"
SLOT="0"
if [ "${PV%9999}" = "${PV}" ] ; then
	KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
else
	KEYWORDS=""
fi
IUSE="egl opengl wayland X"

VIDEO_CARDS="dummy nvidia intel fglrx"
for x in ${VIDEO_CARDS}; do
	IUSE+=" video_cards_${x}"
done

RDEPEND=">=x11-libs/libdrm-2.4
	X? (
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXfixes
	)
	egl? ( media-libs/mesa[egl] )
	opengl? ( virtual/opengl )
	wayland? ( >=dev-libs/wayland-0.95.0 )"

DEPEND="${RDEPEND}
	virtual/pkgconfig"
PDEPEND="video_cards_nvidia? ( x11-libs/libva-vdpau-driver )
	video_cards_fglrx? ( x11-libs/xvba-video )
	video_cards_intel? ( >=x11-libs/libva-intel-driver-1.0.18 )
	"

REQUIRED_USE="opengl? ( X )"

src_prepare() {
	eautoreconf
}

src_configure() {
	econf \
		--disable-silent-rules \
		--with-drivers-path="${EPREFIX}/usr/$(get_libdir)/va/drivers" \
		$(use_enable video_cards_dummy dummy-driver) \
		$(use_enable opengl glx) \
		$(use_enable X x11) \
		$(use_enable wayland) \
		$(use_enable egl)
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc NEWS || die
	find "${D}" -name '*.la' -delete
}
