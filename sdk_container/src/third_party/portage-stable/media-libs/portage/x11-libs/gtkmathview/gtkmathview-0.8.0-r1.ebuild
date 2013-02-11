# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/gtkmathview/gtkmathview-0.8.0-r1.ebuild,v 1.9 2012/12/19 16:46:43 tetromino Exp $

EAPI="4"

inherit autotools eutils

DESCRIPTION="Rendering engine for MathML documents"
HOMEPAGE="http://helm.cs.unibo.it/mml-widget/"
SRC_URI="http://helm.cs.unibo.it/mml-widget/sources/${P}.tar.gz"

LICENSE="LGPL-3"

SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86"
IUSE="gtk mathml svg t1lib"

RDEPEND=">=dev-libs/glib-2.2.1:2
	>=dev-libs/popt-1.7
	>=dev-libs/libxml2-2.6.7:2
	gtk? ( >=x11-libs/gtk+-2.2.1:2
		>=media-libs/t1lib-5:5
		>=dev-libs/gmetadom-0.1.8
		x11-libs/pango
		|| ( x11-libs/pangox-compat <x11-libs/pango-1.31[X] ) )
	mathml? ( media-fonts/texcm-ttf )
	t1lib?	( >=media-libs/t1lib-5:5 )"
DEPEND="${RDEPEND}
	dev-libs/libxslt
	virtual/pkgconfig"

pkg_setup() {
	DOCS="ANNOUNCEMENT AUTHORS BUGS ChangeLog CONTRIBUTORS HISTORY NEWS README TODO"
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-gcc43.patch \
		"${FILESDIR}"/${P}-gcc44.patch \
		"${FILESDIR}"/${P}-cond-t1.patch

	# Fix building against libxml2[icu], bug #356095
	epatch "${FILESDIR}"/${P}-fix-template.patch

	# Fix building with gold, bug #369117; requires eautoreconf
	epatch "${FILESDIR}/${P}-underlinking.patch"

	# m4 macros from upstream git, required for eautoreconf
	if [[ ! -d ac-helpers ]]; then
		mkdir ac-helpers || die "mkdir failed"
		cp "${FILESDIR}/binreloc.m4" ac-helpers || die "cp failed"
	fi

	AT_M4DIR=ac-helpers eautoreconf
}

src_configure() {
	# --disable-popt will build only the library and not the frontend
	# TFM is needed for SVG, default value is 2
	econf $(use_enable gtk) $(use_enable gtk gmetadom) \
		$(use_enable svg) \
		$(use_with t1lib) \
		--with-popt \
		--enable-libxml2 \
		--enable-libxml2-reader \
		--enable-ps \
		--enable-tfm=2 \
		--enable-builder-cache \
		--enable-breaks \
		--enable-boxml \
		--disable-static
}

src_install() {
	default
	find "${D}" -name '*.la' -exec rm -f {} +
}
