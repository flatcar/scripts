# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/spandsp/spandsp-0.0.6_pre12-r1.ebuild,v 1.5 2012/12/17 17:35:14 ago Exp $

EAPI="2"

inherit multilib versionator

DESCRIPTION="SpanDSP is a library of DSP functions for telephony."
HOMEPAGE="http://www.soft-switch.org/"
SRC_URI="http://www.soft-switch.org/downloads/spandsp/${P/_}.tgz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ~ppc ~ppc64 x86"
IUSE="doc fixed-point mmx sse sse2 sse3 static-libs"

RDEPEND="media-libs/tiff"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen
		dev-libs/libxslt )"

S=${WORKDIR}/${PN}-$(get_version_component_range 1-3)

# TODO:
# there are two tests options: tests and test-data
# 	they need audiofile, fftw, libxml and probably more
# configure script is auto-enabling some sse* options sometimes

src_configure() {
	econf \
		--disable-dependency-tracking \
		$(use_enable doc) \
		$(use_enable fixed-point) \
		$(use_enable mmx) \
		$(use_enable sse) \
		$(use_enable sse2) \
		$(use_enable sse3) \
		$(use_enable static-libs static)
}

src_install () {
	emake DESTDIR="${D}" install || die	"emake install failed"
	dodoc AUTHORS ChangeLog DueDiligence NEWS README || die "dodoc failed"

	if ! use static-libs; then
		# remove useless la file when not installing static lib
		rm "${D}"/usr/$(get_libdir)/lib${PN}.la || die "rm failed"
	fi

	if use doc; then
		dohtml -r doc/{api/html/*,t38_manual} || die "dohtml failed"
	fi
}
