# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-drivers/xf86-video-nouveau/xf86-video-nouveau-0.0.16_pre20110323.ebuild,v 1.4 2011/06/28 20:06:31 ranger Exp $

EAPI=3
XORG_EAUTORECONF="yes"
inherit linux-info xorg-2

DESCRIPTION="Accelerated Open Source driver for nVidia cards"
HOMEPAGE="http://nouveau.freedesktop.org/"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

KEYWORDS="amd64 ppc ~ppc64 x86"
IUSE=""

RDEPEND=">=x11-base/xorg-server-1.8[-minimal]
	>=x11-libs/libdrm-2.4.24[video_cards_nouveau]"

DEPEND="${RDEPEND}
	x11-proto/dri2proto
	x11-proto/fontsproto
	x11-proto/randrproto
	x11-proto/renderproto
	x11-proto/videoproto
	x11-proto/xextproto
	x11-proto/xf86driproto
	x11-proto/xproto"

pkg_postinst() {
	xorg-2_pkg_postinst
	if ! has_version x11-base/nouveau-drm; then
		if ! linux_config_exists || ! linux_chkconfig_present DRM_NOUVEAU; then
			ewarn "Nouveau DRM not detected. If you want any kind of"
			ewarn "acceleration with nouveau, enable CONFIG_DRM_NOUVEAU"
			ewarn "in the kernel."
		fi
	fi
}
