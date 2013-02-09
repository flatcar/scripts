# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libquicktime/libquicktime-1.2.3-r1.ebuild,v 1.5 2012/05/05 08:02:34 jdhore Exp $

EAPI=4

inherit libtool eutils

MY_P=${P/_pre/pre}

DESCRIPTION="A library based on quicktime4linux with extensions"
HOMEPAGE="http://libquicktime.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd"
IUSE="mmx X opengl dv gtk alsa aac encode png jpeg vorbis lame x264 ffmpeg doc schroedinger"

RDEPEND="dv? ( media-libs/libdv )
	gtk? ( >=x11-libs/gtk+-2.4.0:2 )
	aac? (
		media-libs/faad2
		encode? ( media-libs/faac )
	)
	alsa? ( >=media-libs/alsa-lib-1.0.16 )
	png? ( media-libs/libpng )
	jpeg? ( virtual/jpeg )
	vorbis? ( media-libs/libvorbis media-libs/libogg )
	lame? ( media-sound/lame )
	ffmpeg? ( virtual/ffmpeg )
	x264? ( media-libs/x264 )
	schroedinger? ( >=media-libs/schroedinger-1.0.5 )
	X? ( x11-libs/libXaw
		x11-libs/libXv
		x11-libs/libXext
		x11-libs/libX11
		opengl? ( media-libs/mesa )
	)
	virtual/libintl"
DEPEND="${RDEPEND}
	X? (
		x11-proto/videoproto
		x11-proto/xextproto
	)
	doc? ( app-doc/doxygen )
	virtual/pkgconfig
	sys-devel/gettext"

S=${WORKDIR}/${MY_P}

src_prepare() {
	# Needed for sane .so versionning on g/fbsd
	elibtoolize
}

src_configure() {
	local MY_OPTS=""
	if use !encode || use !aac; then
		MY_OPTS="--without-faac"
	fi

	econf --enable-shared \
		--enable-static \
		--enable-gpl \
		$(use_with doc doxygen) \
		$(use_enable mmx asm) \
		$(use_with X x) \
		$(use_with gtk) \
		$(use_with dv libdv) \
		$(use_with alsa) \
		$(use_with aac faad2) \
		$(use_with png libpng) \
		$(use_with jpeg libjpeg) \
		$(use vorbis || echo "--without-vorbis") \
		$(use_with lame) \
		$(use_with x264) \
		$(use_with ffmpeg) \
		$(use_with opengl) \
		$(use_with schroedinger) \
		${MY_OPTS} \
		--without-cpuflags
}

src_install() {
	default
	dodoc README TODO ChangeLog
	# Compatibility with software that uses quicktime prefix, but
	# don't do that when building for Darwin/MacOS
	[[ ${CHOST} != *-darwin* ]] && \
	dosym /usr/include/lqt /usr/include/quicktime
}

pkg_preinst() {
	if [[ -d /usr/include/quicktime && ! -L /usr/include/quicktime ]]; then
		elog "For compatibility with other quicktime libraries, ${PN} was"
		elog "going to create a /usr/include/quicktime symlink, but for some"
		elog "reason that is a directory on your system."

		elog "Please check that is empty, and remove it, or submit a bug"
		elog "telling us which package owns the directory."
		die "/usr/include/quicktime is a directory."
	fi
}
