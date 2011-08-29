# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libva/libva-1.0.14.ebuild,v 1.2 2011/07/29 01:10:12 zmedico Exp $

EAPI="3"

SCM=""
if [ "${PV%9999}" != "${PV}" ] ; then # Live ebuild
	SCM=git-2
	EGIT_BRANCH=master
	EGIT_REPO_URI="git://anongit.freedesktop.org/git/libva"
fi

inherit autotools ${SCM} multilib

DESCRIPTION="Video Acceleration (VA) API for Linux"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/vaapi"
if [ "${PV%9999}" != "${PV}" ] ; then # Live ebuild
	SRC_URI=""
	S="${WORKDIR}/${PN}"
else
	SRC_URI="http://cgit.freedesktop.org/libva/snapshot/${P}.tar.bz2"
fi

LICENSE="MIT"
SLOT="0"
if [ "${PV%9999}" = "${PV}" ] ; then
	KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
else
	KEYWORDS=""
fi
IUSE="opengl"

VIDEO_CARDS="dummy nvidia intel fglrx"
for x in ${VIDEO_CARDS}; do
	IUSE+=" video_cards_${x}"
done

RDEPEND=">=x11-libs/libdrm-2.4
	video_cards_intel? ( >=x11-libs/libdrm-2.4.23[video_cards_intel] )
	video_cards_dummy? ( sys-fs/udev )
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXfixes
	opengl? ( virtual/opengl )"

DEPEND="${RDEPEND}
	dev-util/pkgconfig"
PDEPEND="video_cards_nvidia? ( x11-libs/vdpau-video )
	video_cards_fglrx? ( x11-libs/xvba-video )"

src_prepare() {
	eautoreconf
}

src_configure() {
	econf \
		--with-drivers-path="${EPREFIX}/usr/$(get_libdir)/va/drivers" \
		$(use_enable video_cards_dummy dummy-driver) \
		$(use_enable video_cards_dummy dummy-backend) \
		$(use_enable video_cards_intel i965-driver) \
		$(use_enable opengl glx)
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"
	find "${D}" -name '*.la' -delete
}
