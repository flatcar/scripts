# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/gtkdatabox/gtkdatabox-0.9.1.3.ebuild,v 1.1 2011/10/02 12:01:07 pva Exp $

EAPI="4"

DESCRIPTION="Gtk+ Widgets for live display of large amounts of fluctuating numerical data"
HOMEPAGE="http://sourceforge.net/projects/gtkdatabox/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc +glade test"

RDEPEND="x11-libs/gtk+:2
	x11-libs/pango
	x11-libs/cairo
	glade? (
		dev-util/glade:3
		gnome-base/libglade
	)
"

DEPEND=${RDEPEND}

src_prepare() {
	# Remove -D.*DISABLE_DEPRECATED cflags
	find . -iname 'Makefile.am' -exec \
		sed -e '/-D[A-Z_]*DISABLE_DEPRECATED/d' -i {} + || die "sed 1 failed"
	# Do Makefile.in after Makefile.am to avoid automake maintainer-mode
	find . -iname 'Makefile.in' -exec \
		sed -e '/-D[A-Z_]*DISABLE_DEPRECATED/d' -i {} + || die "sed 2 failed"
	sed -e '/SUBDIRS/{s: examples::;}' -i Makefile.am -i Makefile.in || die
}

src_configure() {
	econf \
		--enable-libtool-lock \
		--disable-dependency-tracking \
		$(use_enable glade libglade) \
		$(use_enable glade) \
		$(use_enable doc gtk-doc) \
		$(use_enable test gtktest)
}

src_install() {
	emake DESTDIR="${D}" install

	dodoc AUTHORS ChangeLog README TODO
	docinto examples
	dodoc "${S}"/examples/*
}
