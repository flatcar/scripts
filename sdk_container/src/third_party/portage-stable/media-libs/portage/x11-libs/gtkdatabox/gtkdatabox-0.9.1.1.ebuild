# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/gtkdatabox/gtkdatabox-0.9.1.1.ebuild,v 1.4 2010/12/16 18:42:07 pacho Exp $

EAPI="2"

DESCRIPTION="Gtk+ Widgets for live display of large amounts of fluctuating numerical data"
HOMEPAGE="http://sourceforge.net/projects/gtkdatabox/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc examples +glade test"

RDEPEND="x11-libs/gtk+:2
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
	emake DESTDIR="${D}" install || die "Installation Failed"

	dodoc AUTHORS ChangeLog README TODO || die "dodoc failed"

	if use examples; then
		emake clean -C examples || die "Cleaning examples failed"
		docinto examples
		dodoc "${S}"/examples/* || die "Copy examples to doc failed."
	fi
}
