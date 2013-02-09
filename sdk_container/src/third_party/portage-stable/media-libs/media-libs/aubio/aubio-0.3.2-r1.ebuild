# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/aubio/aubio-0.3.2-r1.ebuild,v 1.12 2012/05/05 08:02:31 jdhore Exp $

EAPI=3

PYTHON_DEPEND="2:2.6"

inherit autotools eutils python

DESCRIPTION="Library for audio labelling"
HOMEPAGE="http://aubio.piem.org"
SRC_URI="http://aubio.piem.org/pub/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc ppc64 sparc x86"
IUSE="alsa doc jack lash static-libs"

RDEPEND="sci-libs/fftw:3.0
	media-libs/libsndfile
	media-libs/libsamplerate
	|| ( dev-lang/python:2.7 dev-lang/python:2.6 )
	alsa? ( media-libs/alsa-lib )
	jack? ( media-sound/jack-audio-connection-kit )
	lash? ( media-sound/lash )"
DEPEND="${RDEPEND}
	>=dev-lang/swig-1.3.0
	virtual/pkgconfig
	doc? ( app-doc/doxygen virtual/latex-base )"

pkg_setup() {
	DOCS=( AUTHORS ChangeLog README TODO )

	python_set_active_version 2
	python_pkg_setup
}

src_prepare() {
	epatch "${FILESDIR}"/aubio-0.3.2-multilib.patch
	eautoreconf
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_enable jack) \
		$(use_enable alsa) \
		$(use_enable lash)
}

src_compile() {
	default

	if use doc; then
		export VARTEXFONTS="${T}/fonts"
		cd "${S}"/doc
		doxygen user.cfg
		doxygen devel.cfg
		doxygen examples.cfg
	fi
}

src_install() {
	# `default` would be enough here if python.eclass supported EAPI=4
	emake DESTDIR="${D}" install || die
	dodoc "${DOCS[@]}"

	doman doc/*.1
	if use doc; then
		mv doc/user/html doc/user/user
		dohtml -r doc/user/user
		mv doc/devel/html doc/devel/devel
		dohtml -r doc/devel/devel
		mv doc/examples/html doc/examples/examples
		dohtml -r doc/examples/examples
	fi

	find "${ED}"usr -name '*.la' -exec rm -f {} +
}

pkg_postinst() { python_mod_optimize aubio; }
pkg_postrm() { python_mod_cleanup aubio; }
