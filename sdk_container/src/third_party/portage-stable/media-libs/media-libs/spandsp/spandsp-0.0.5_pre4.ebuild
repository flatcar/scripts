# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/spandsp/spandsp-0.0.5_pre4.ebuild,v 1.1 2008/06/20 10:08:31 drac Exp $

inherit versionator

DESCRIPTION="SpanDSP is a library of DSP functions for telephony."
HOMEPAGE="http://www.soft-switch.org/"
SRC_URI="http://www.soft-switch.org/downloads/spandsp/${P/_}.tgz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="doc mmx sse"
# test"

RDEPEND="media-libs/audiofile
	media-libs/tiff
	=sci-libs/fftw-3*"
#	test? ( x11-libs/libXft
#		x11-libs/libXext
#		x11-libs/libX11
#		dev-libs/libxml2
#		x11-libs/fltk )"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen
		dev-libs/libxslt )"

S=${WORKDIR}/${PN}-$(get_version_component_range 1-3)

src_compile() {
	econf --disable-dependency-tracking \
		$(use_enable doc) \
		$(use_enable mmx) \
		$(use_enable sse)
#		$(use_enable test tests) \
#		$(use_enable test test-data)
	emake || die "emake failed."
}

src_install () {
	emake DESTDIR="${D}" install || die	"emake install failed."
	dodoc AUTHORS NEWS README
	use doc && dohtml -r doc/{api/html/*,t38_manual}
}
