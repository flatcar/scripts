# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/freeverb3/freeverb3-2.5.16.ebuild,v 1.2 2011/08/29 09:56:12 sping Exp $

EAPI=2
inherit versionator

DESCRIPTION="High Quality Reverb and Impulse Response Convolution library including XMMS/Audacious Effect plugins"
HOMEPAGE="http://freeverb3.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="audacious jack plugdouble sse sse2 sse3 sse4 3dnow forcefpu"

RDEPEND=">=sci-libs/fftw-3.0.1
	audacious? ( <media-sound/audacious-3
		media-libs/libsndfile )
	jack? ( media-sound/jack-audio-connection-kit
		media-libs/libsndfile )"
DEPEND=${RDEPEND}

S="${WORKDIR}/${PN}-$(get_version_component_range 1-3)"

src_configure() {
	econf \
		--enable-release \
		--disable-bmp \
		--disable-pluginit \
		$(use_enable audacious) \
		$(use_enable jack) \
		$(use_enable plugdouble) \
		$(use_enable 3dnow) \
		$(use_enable sse) \
		$(use_enable sse2) \
		$(use_enable sse3) \
		$(use_enable sse4) \
		$(use_enable forcefpu) \
		|| die "econf failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc ChangeLog README || die 'dodoc failed'

	insinto /usr/share/${PN}/samples/IR
	doins samples/IR/*.wav || die
}
