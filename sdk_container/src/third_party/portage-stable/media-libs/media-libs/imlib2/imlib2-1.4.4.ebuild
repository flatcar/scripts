# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/imlib2/imlib2-1.4.4.ebuild,v 1.12 2012/05/05 08:02:30 jdhore Exp $

EAPI="2"

inherit enlightenment toolchain-funcs

MY_P=${P/_/-}
DESCRIPTION="Version 2 of an advanced replacement library for libraries like libXpm"
HOMEPAGE="http://www.enlightenment.org/"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd"
IUSE="X bzip2 gif jpeg mmx mp3 png tiff zlib"

RDEPEND="=media-libs/freetype-2*
	bzip2? ( app-arch/bzip2 )
	zlib? ( sys-libs/zlib )
	gif? ( >=media-libs/giflib-4.1.0 )
	png? ( >=media-libs/libpng-1.4 )
	jpeg? ( virtual/jpeg )
	tiff? ( >=media-libs/tiff-3.5.5 )
	X? ( x11-libs/libXext x11-proto/xextproto )
	mp3? ( media-libs/libid3tag )"
DEPEND="${RDEPEND}
	png? ( virtual/pkgconfig )"

src_prepare() {
	epatch "${FILESDIR}"/${P}-libpng-1.5.patch #354989
}

src_configure() {
	# imlib2 has diff configure options for x86/amd64 mmx
	local myconf=""
	if [[ $(tc-arch) == "amd64" ]] ; then
		myconf="$(use_enable mmx amd64) --disable-mmx"
	else
		myconf="--disable-amd64 $(use_enable mmx)"
	fi

	[[ $(gcc-major-version) -ge 4 ]] && myconf="${myconf} --enable-visibility-hiding"

	export MY_ECONF="
		$(use_with X x) \
		$(use_with jpeg) \
		$(use_with png) \
		$(use_with tiff) \
		$(use_with gif) \
		$(use_with zlib) \
		$(use_with bzip2) \
		$(use_with mp3 id3) \
		${myconf} \
	"
	enlightenment_src_configure
}
