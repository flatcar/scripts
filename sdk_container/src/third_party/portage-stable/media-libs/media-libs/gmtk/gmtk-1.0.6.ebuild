# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gmtk/gmtk-1.0.6.ebuild,v 1.4 2012/06/08 11:32:01 phajdan.jr Exp $

EAPI=4

DESCRIPTION="GTK+ widget and function libraries for gnome-mplayer"
HOMEPAGE="http://code.google.com/p/gmtk/"
SRC_URI="http://${PN}.googlecode.com/files/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 ~ppc ~ppc64 x86"
IUSE="alsa +dconf pulseaudio"

COMMON_DEPEND=">=dev-libs/glib-2.26
	x11-libs/gtk+:3
	x11-libs/libX11
	alsa? ( media-libs/alsa-lib )
	pulseaudio? ( media-sound/pulseaudio )"
RDEPEND="${COMMON_DEPEND}
	dconf? ( gnome-base/dconf )"
DEPEND="${COMMON_DEPEND}
	dev-util/intltool
	virtual/pkgconfig
	sys-devel/gettext"

DOCS=( ChangeLog )

src_configure() {
	econf \
		--disable-static \
		--enable-gtk3 \
		$(use_enable dconf gsettings) \
		--disable-gconf \
		$(use_enable !dconf keystore) \
		--with-gio \
		$(use_with alsa) \
		$(use_with pulseaudio)
}

src_install() {
	default

	rm -rf \
		"${ED}"usr/share/doc/${PN} \
		"${ED}"usr/lib*/*.la
}
