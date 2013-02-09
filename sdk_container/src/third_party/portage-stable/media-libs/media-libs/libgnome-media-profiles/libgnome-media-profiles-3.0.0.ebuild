# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libgnome-media-profiles/libgnome-media-profiles-3.0.0.ebuild,v 1.3 2012/05/05 08:02:31 jdhore Exp $

EAPI="4"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"
GNOME_TARBALL_SUFFIX="bz2"

inherit gnome2

DESCRIPTION="GNOME Media Profiles library"
HOMEPAGE="http://git.gnome.org/browse/libgnome-media-profiles"

LICENSE="LGPL-2"
SLOT="3"
KEYWORDS="~amd64 ~x86"
IUSE="aac flac mp3 speex twolame vorbis"

# FIXME: automagic dep on gladeui-3.0
# these guys are just copy-pasting configure code b/w modules with all the bugs
COMMON_DEPEND="
	dev-libs/glib:2
	>=x11-libs/gtk+-2.91.0:3
	>=media-libs/gstreamer-0.10.23:0.10
	>=media-libs/gst-plugins-base-0.10.23:0.10
	gnome-base/gconf:2"
# Specific gst plugins are used by the default audio encoding profiles
# NOTE: Audio profile stuff moved from gnome-media to here, so we add a blocker
#       to avoid collisions
RDEPEND="${COMMON_DEPEND}
	media-plugins/gst-plugins-meta:0.10[flac?,vorbis?]
	aac? (
		media-plugins/gst-plugins-faac:0.10
		media-plugins/gst-plugins-ffmpeg:0.10 )
	mp3? (
		media-libs/gst-plugins-ugly:0.10
		media-plugins/gst-plugins-taglib:0.10
		media-plugins/gst-plugins-lame:0.10 )
	speex? (
		media-plugins/gst-plugins-ogg:0.10
		media-plugins/gst-plugins-speex:0.10 )
	twolame? (
		media-plugins/gst-plugins-taglib:0.10
		media-plugins/gst-plugins-twolame:0.10 )

	!<gnome-extra/gnome-media-2.32.0-r300"
DEPEND="${COMMON_DEPEND}
	app-text/gnome-doc-utils
	>=dev-util/intltool-0.35.0
	virtual/pkgconfig
	sys-devel/gettext"

pkg_setup() {
	DOCS="ChangeLog NEWS README"
	G2CONF="${G2CONF} --disable-static"
}
