# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libcanberra/libcanberra-0.30-r1.ebuild,v 1.1 2012/12/19 02:43:32 tetromino Exp $

EAPI="5"

inherit eutils systemd

DESCRIPTION="Portable sound event library"
HOMEPAGE="http://0pointer.de/lennart/projects/libcanberra/"
SRC_URI="http://0pointer.de/lennart/projects/${PN}/${P}.tar.xz"

LICENSE="LGPL-2.1+"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~sparc-solaris ~x86-solaris"
IUSE="alsa gnome gstreamer +gtk +gtk3 oss pulseaudio +sound tdb udev"

COMMON_DEPEND="media-libs/libvorbis
	>=sys-devel/libtool-2.2.6b
	alsa? (
		media-libs/alsa-lib:=
		udev? ( >=virtual/udev-171:= ) )
	gstreamer? ( media-libs/gstreamer:1.0 )
	gtk? (
		>=dev-libs/glib-2.32:2
		>=x11-libs/gtk+-2.20.0:2
		x11-libs/libX11 )
	gtk3? (
		>=dev-libs/glib-2.32:2
		x11-libs/gtk+:3
		x11-libs/libX11 )
	pulseaudio? ( >=media-sound/pulseaudio-0.9.11 )
	tdb? ( sys-libs/tdb:= )
"
RDEPEND="${COMMON_DEPEND}
	gnome? ( gnome-base/gsettings-desktop-schemas )
	sound? ( x11-themes/sound-theme-freedesktop )" # Required for index.theme wrt #323379
DEPEND="${COMMON_DEPEND}
	app-arch/xz-utils
	virtual/pkgconfig"

REQUIRED_USE="udev? ( alsa )"

src_configure() {
	econf \
		--docdir="${EPREFIX}"/usr/share/doc/${PF} \
		$(use_enable alsa) \
		$(use_enable oss) \
		$(use_enable pulseaudio pulse) \
		$(use_enable gstreamer) \
		$(use_enable gtk) \
		$(use_enable gtk3) \
		$(use_enable tdb) \
		$(use_enable udev) \
		$(systemd_with_unitdir) \
		--disable-lynx \
		--disable-gtk-doc
}

src_install() {
	# Disable parallel installation until bug #253862 is solved
	MAKEOPTS="${MAKEOPTS} -j1" default
	prune_libtool_files --modules
}
