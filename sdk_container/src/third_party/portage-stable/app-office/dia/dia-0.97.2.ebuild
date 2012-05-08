# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-office/dia/dia-0.97.2.ebuild,v 1.7 2012/05/03 20:00:39 jdhore Exp $

EAPI=4

GCONF_DEBUG=yes
GNOME2_LA_PUNT=yes

PYTHON_DEPEND="python? 2"

inherit autotools eutils gnome2 python multilib

DESCRIPTION="Diagram/flowchart creation program"
HOMEPAGE="http://live.gnome.org/Dia"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 ~hppa ~ia64 ~ppc ppc64 ~sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos"
# the doc USE flag doesn't seem to do anything without docbook2html
IUSE="cairo doc gnome python"

RDEPEND=">=dev-libs/glib-2
	dev-libs/libxml2
	dev-libs/libxslt
	dev-libs/popt
	>=media-libs/freetype-2
	>=media-libs/libart_lgpl-2
	media-libs/libpng
	sys-libs/zlib
	x11-libs/gtk+:2
	x11-libs/pango
	cairo? ( x11-libs/cairo )
	doc? (
		app-text/docbook-xml-dtd:4.5
		app-text/docbook-xsl-stylesheets
		)
	gnome? (
		>=gnome-base/libgnome-2
		>=gnome-base/libgnomeui-2
		)
	python? ( >=dev-python/pygtk-2 )"
DEPEND="${RDEPEND}
	dev-util/intltool
	virtual/pkgconfig
	doc? ( dev-libs/libxslt )"

pkg_setup() {
	DOCS="AUTHORS ChangeLog KNOWN_BUGS MAINTAINERS NEWS README RELEASE-PROCESS THANKS TODO"

	# --exec-prefix makes Python look for modules in the Prefix
	G2CONF="--exec-prefix=${EPREFIX}/usr
		--docdir=${EPREFIX}/usr/share/doc/${PF}
		$(use_enable gnome)
		--disable-libemf
		$(use_enable doc db2html)
		$(use_with cairo)
		$(use_with python)
		--without-swig
		--without-hardbooks"

	if use python; then
		python_set_active_version 2
		python_pkg_setup
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-0.97.0-gnome-doc.patch #159831
	epatch "${FILESDIR}"/${PN}-0.97.2-glib-2.31.patch #401331

	if use python; then
		python_convert_shebangs -r 2 .
		sed -i -e "s/\.so/$(get_libname)/" acinclude.m4 || die #298232
	fi

	if ! use doc; then
		# Skip man generation
		sed -i -e '/if HAVE_DB2MAN/,/endif/d' doc/*/Makefile.am || die
	fi

	# Fix naming conflict on Darwin/OSX
	sed -i -e 's/isspecial/char_isspecial/' objects/GRAFCET/boolequation.c || die

	intltoolize --force --copy --automake || die
	eautoreconf

	gnome2_src_prepare
}

pkg_postinst() {
	gnome2_pkg_postinst

	if use python; then
		python_need_rebuild
		python_mod_optimize /usr/share/dia
	fi
}

pkg_postrm() {
	gnome2_pkg_postrm

	use python && python_mod_cleanup /usr/share/dia
}
