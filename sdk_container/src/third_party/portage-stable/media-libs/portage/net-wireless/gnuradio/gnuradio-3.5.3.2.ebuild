# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/gnuradio/gnuradio-3.5.3.2.ebuild,v 1.3 2012/07/27 18:19:18 kensington Exp $

EAPI=4
PYTHON_DEPEND="2"

inherit eutils fdo-mime python

DESCRIPTION="Toolkit that provides signal processing blocks to implement software radios"
HOMEPAGE="http://gnuradio.org/"
SRC_URI="http://gnuradio.org/redmine/attachments/download/324/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="audio doc dot examples fcd grc guile qt4 sdl utils wxwidgets"
REQUIRED_USE="utils? ( wxwidgets )
	fcd? ( audio )"

# bug #348206
# comedi? ( >=sci-electronics/comedilib-0.7 )
# uhd? ( dev-libs/uhd )
RDEPEND="dev-libs/boost
	dev-python/numpy
	dev-util/cppunit
	sci-libs/fftw:3.0
	sci-libs/gsl
	virtual/cblas
	fcd? ( virtual/libusb:1 )
	audio? (
		media-libs/alsa-lib
		media-sound/jack-audio-connection-kit
		>=media-libs/portaudio-19_pre
	)
	grc? (
		dev-python/cheetah
		dev-python/lxml
		dev-python/pygtk:2
	)
	guile? ( >=dev-scheme/guile-1.8.4 )
	qt4? (
		dev-python/PyQt4[X,opengl]
		dev-python/pyqwt:5
		x11-libs/qt-gui:4
	)
	sdl? ( media-libs/libsdl )
	wxwidgets? (
		dev-python/wxpython:2.8
		dev-python/numpy
	)
"
# gnuradio links against older version of itself during build
DEPEND="${RDEPEND}
	!!<${CATEGORY}/${P}
	dev-lang/swig
	virtual/pkgconfig
	doc? (
		>=app-doc/doxygen-1.5.7.1[dot?]
		app-text/xmlto
	)
	grc? (
		x11-misc/xdg-utils
	)
"

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup
}

src_prepare() {
	python_convert_shebangs -q -r 2 "${S}"
	# Useless UI element would require qt3support, bug #365019
	sed -i '/qPixmapFromMimeSource/d' "${S}"/gr-qtgui/lib/spectrumdisplayform.ui || die
	# TODO: DEPDIR is not created, need to investigate why
	mkdir "${S}"/gnuradio-core/src/lib/general/.deps || die
	mkdir "${S}"/gnuradio-core/src/lib/gengen/.deps || die
	mkdir "${S}"/gr-trellis/src/lib/.deps || die
}

src_configure() {
	# --with-lv_arch=32 fails to build on amd64
	# TODO: more elegant solution is required before keywording on other arches
	# TODO: docs are installed to /usr/share/doc/${PN} not /usr/share/doc/${PF}
	econf \
		--enable-all-components \
		--enable-gnuradio-core \
		--enable-gruel \
		--enable-python \
		--disable-gr-comedi \
		--disable-gr-shd \
		--disable-gr-uhd \
		--with-lv_arch="generic 64 3dnow abm popcount mmx sse sse2 sse3 ssse3 sse4_a sse4_1 sse4_2 avx" \
		$(use_enable audio gr-audio) \
		$(use_enable doc doxygen) \
		$(use_enable doc docs) \
		$(use_enable dot) \
		$(use_enable examples gnuradio-examples) \
		$(use_enable fcd gr-fcd) \
		$(use_enable grc) \
		$(use_enable guile) \
		$(use_enable utils gr-utils) \
		$(use_enable wxwidgets gr-wxgui) \
		$(use_enable sdl gr-video-sdl) \
		$(use sdl || echo "--disable-sdltest") \
		$(use_enable qt4 gr-qtgui) \
		$(use_with qt4 qwt-incdir "${EPREFIX}"/usr/include/qwt5)
}

src_install() {
	# Fails to install with parallel make sometimes, bug #412449
	emake -j1 DESTDIR="${ED}" install

	python_clean_installation_image -q

	# Install examples to /usr/share/doc/$PF
	if use examples ; then
		dodir /usr/share/doc/${PF}/
		mv "${ED}"/usr/share/gnuradio/examples "${ED}"/usr/share/doc/${PF}/ || die "failed installing examples"
	else
	# It seems that the examples are installed whether configured or not
		rm -rf "${ED}"/usr/share/gnuradio/examples || die
	fi

	# Remove useless files in the doc dir
	if use doc; then
		rm -f "${ED}"/usr/share/doc/${P}/html/*.md5 || die
	fi

	# We install the mimetypes to the correct locations from the ebuild
	rm -rf "${ED}"/usr/share/gnuradio/grc/freedesktop || die
	rm -f "${ED}"/usr/bin/grc_setup_freedesktop || die

	# Install icons, menu items and mime-types for GRC
	if use grc ; then
		local fd_path="${S}/grc/freedesktop"
		insinto /usr/share/mime/packages
		doins "${fd_path}/gnuradio-grc.xml"

		domenu "${fd_path}/"*.desktop
		doicon "${fd_path}/"*.png
	fi
}

pkg_postinst()
{
	local GRC_ICON_SIZES="32 48 64 128 256"
	python_mod_optimize gnuradio

	if use grc ; then
		fdo-mime_desktop_database_update
		fdo-mime_mime_database_update
		for size in ${GRC_ICON_SIZES} ; do
			xdg-icon-resource install --noupdate --context mimetypes --size ${size} \
				"${ROOT}/usr/share/pixmaps/grc-icon-${size}.png" application-gnuradio-grc \
				|| die "icon resource installation failed"
			xdg-icon-resource install --noupdate --context apps --size ${size} \
				"${ROOT}/usr/share/pixmaps/grc-icon-${size}.png" gnuradio-grc \
				|| die "icon resource installation failed"
		done
		xdg-icon-resource forceupdate
	fi
}

pkg_postrm()
{
	local GRC_ICON_SIZES="32 48 64 128 256"
	python_mod_cleanup gnuradio

	if use grc ; then
		fdo-mime_desktop_database_update
		fdo-mime_mime_database_update
		for size in ${GRC_ICON_SIZES} ; do
			xdg-icon-resource uninstall --noupdate --context mimetypes --size ${size} \
				application-gnuradio-grc || ewarn "icon uninstall failed"
			xdg-icon-resource uninstall --noupdate --context apps --size ${size} \
				gnuradio-grc || ewarn "icon uninstall failed"

		done
		xdg-icon-resource forceupdate
	fi
}
