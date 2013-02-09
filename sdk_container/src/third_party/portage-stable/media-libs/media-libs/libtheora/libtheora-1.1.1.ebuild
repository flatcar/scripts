# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libtheora/libtheora-1.1.1.ebuild,v 1.10 2012/05/15 13:09:16 aballier Exp $

EAPI=2
inherit autotools eutils flag-o-matic

DESCRIPTION="The Theora Video Compression Codec"
HOMEPAGE="http://www.theora.org"
SRC_URI="http://downloads.xiph.org/releases/theora/${P/_}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~amd64-fbsd ~x86-fbsd"
IUSE="doc +encode examples static-libs"

RDEPEND="media-libs/libogg
	encode? ( media-libs/libvorbis )
	examples? ( media-libs/libpng
		media-libs/libvorbis
		>=media-libs/libsdl-0.11.0 )"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	virtual/pkgconfig"

VARTEXFONTS=${T}/fonts
S=${WORKDIR}/${P/_}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.0_beta2-flags.patch
	AT_M4DIR="m4" eautoreconf
}

src_configure() {
	use x86 && filter-flags -fforce-addr -frename-registers #200549
	use doc || export ac_cv_prog_HAVE_DOXYGEN="false"

	local myconf
	use examples && myconf="--enable-encode"

	# --disable-spec because LaTeX documentation has been prebuilt
	econf \
		--disable-dependency-tracking \
		$(use_enable static-libs static) \
		--disable-spec \
		$(use_enable encode) \
		$(use_enable examples) \
		${myconf}
}

src_install() {
	emake DESTDIR="${D}" docdir=/usr/share/doc/${PF} \
		install || die "emake install failed"

	dodoc AUTHORS CHANGES README
	prepalldocs

	if use examples; then
		if use doc; then
			insinto /usr/share/doc/${PF}/examples
			doins examples/*.[ch]
		fi

		dobin examples/.libs/png2theora || die "dobin failed"
		for bin in dump_{psnr,video} {encoder,player}_example; do
			newbin examples/.libs/${bin} theora_${bin} || die "newbin failed"
		done
	fi

	find "${D}" -name '*.la' -exec rm -f '{}' +
}
