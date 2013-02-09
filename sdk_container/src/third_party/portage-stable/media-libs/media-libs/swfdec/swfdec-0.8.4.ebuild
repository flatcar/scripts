# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/swfdec/swfdec-0.8.4.ebuild,v 1.13 2012/05/05 08:02:44 jdhore Exp $

EAPI=1

inherit eutils versionator

MY_PV=$(get_version_component_range 1-2)
DESCRIPTION="Macromedia Flash decoding library"
HOMEPAGE="http://swfdec.freedesktop.org"
SRC_URI="http://swfdec.freedesktop.org/download/${PN}/${MY_PV}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux"

IUSE="alsa doc ffmpeg gstreamer +gtk pulseaudio"

RDEPEND=">=dev-libs/glib-2.16:2
	>=dev-libs/liboil-0.3.1
	>=x11-libs/pango-1.16.4
	gtk? (
		>=x11-libs/gtk+-2.8.0:2
		net-libs/libsoup:2.4
		)
	>=x11-libs/cairo-1.6
	gstreamer? (
		>=media-libs/gstreamer-0.10.11:0.10
		>=media-libs/gst-plugins-base-0.10.15:0.10
		ffmpeg? ( media-plugins/gst-plugins-ffmpeg:0.10 )
		)
	alsa? ( >=media-libs/alsa-lib-1.0.12 )
	pulseaudio? ( media-sound/pulseaudio )"

DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( >=dev-util/gtk-doc-1.6 )"

RESTRICT="test"

pkg_setup() {
	if use !gtk ; then
		ewarn "swfdec will be built without swfdec-gtk convenience"
		ewarn "library, which is needed by swfdec-mozilla and"
		ewarn "swfdec-gnome. Please add 'gtk' to your USE flags"
		ewarn "unless you really know what you are doing."
	fi

	if use !gstreamer && use ffmpeg; then
		ewarn
		ewarn "The 'ffmpeg' USE flag enables video support via gst-plugins-ffmpeg"
		ewarn "as such it requires the 'gstreamer' USE flag to be enabled."
	fi

	if use alsa && use pulseaudio; then
		ewarn
		ewarn "Pulseaudio and ALSA selected. Selecting mature ALSA backend."
	fi
}

src_compile() {
	# Backend logic is from configure.ac:
	# alsa > pulseaudio
	local audio="none"
	use pulseaudio && audio="pulse"
	use alsa && audio="alsa"

	# bug #216009
	# avoid writing to /root/.gstreamer-0.10/registry.xml
	export GST_REGISTRY="${T}"/registry.xml
	# also avoid loading gconf plugins, which may write to /root/.gconfd
	export GST_PLUGIN_SYSTEM_PATH="${T}"

	econf \
		$(use_enable doc gtk-doc) \
		$(use_enable gstreamer) \
		$(use_enable gtk) \
		--with-audio=${audio} || die "configure failed"

	# bug #216284 image tests are not ready yet
	cat  >test/image/Makefile <<EOF
all:
check:
install:
EOF

	emake || die "emake failed"
}

src_install() {
	emake install DESTDIR="${D}" || die "emake install failed"
	dodoc AUTHORS ChangeLog README
}
