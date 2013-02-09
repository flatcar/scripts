# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/imlib2/imlib2-1.4.5.ebuild,v 1.9 2012/09/29 18:40:34 armin76 Exp $

EAPI=4
inherit enlightenment toolchain-funcs

DESCRIPTION="Version 2 of an advanced replacement library for libraries like libXpm"
HOMEPAGE="http://www.enlightenment.org/"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~amd64-fbsd ~x86-fbsd"
IUSE="X bzip2 gif jpeg mmx mp3 png static-libs tiff zlib"

RDEPEND="=media-libs/freetype-2*
	bzip2? ( app-arch/bzip2 )
	zlib? ( sys-libs/zlib )
	gif? ( >=media-libs/giflib-4.1.0 )
	png? ( media-libs/libpng:0 )
	jpeg? ( virtual/jpeg )
	tiff? ( media-libs/tiff:0 )
	X? (
		x11-libs/libX11
		x11-libs/libXext
		)
	mp3? ( media-libs/libid3tag )"
DEPEND="${RDEPEND}
	png? ( virtual/pkgconfig )
	X? (
		x11-proto/xextproto
		x11-proto/xproto
		)"

src_configure() {
	# imlib2 has diff configure options for x86/amd64 mmx
	local myconf
	if [[ $(tc-arch) == amd64 ]]; then
		myconf="$(use_enable mmx amd64) --disable-mmx"
	else
		myconf="--disable-amd64 $(use_enable mmx)"
	fi

	[[ $(gcc-major-version) -ge 4 ]] && myconf="${myconf} --enable-visibility-hiding"

	export MY_ECONF="
		$(use_enable static-libs static)
		$(use_with X x)
		$(use_with jpeg)
		$(use_with png)
		$(use_with tiff)
		$(use_with gif)
		$(use_with zlib)
		$(use_with bzip2)
		$(use_with mp3 id3)
		${myconf}
		"

	enlightenment_src_configure
}

src_install() {
	enlightenment_src_install

	# enlightenment_src_install should take care of this for us, but it doesn't
	find "${ED}" -name '*.la' -exec rm -f {} +
}
