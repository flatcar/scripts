# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libole2/libole2-0.2.4-r1.ebuild,v 1.11 2008/10/14 02:17:22 darkside Exp $

inherit gnome.org

DESCRIPTION="Library to manipulate OLE2 Structured Storage files"
HOMEPAGE="http://www.gnome.org/"

IUSE=""
SLOT="0"
LICENSE="GPL-2"
KEYWORDS="alpha ~amd64 ppc sparc x86"

RDEPEND="=dev-libs/glib-1.2*"
DEPEND="${RDEPEND}
	dev-util/gtk-doc"

src_unpack() {
	unpack ${A}

	# fix header include, needed for abiword
	cd "${S}"/libole2
	mv ms-ole.h ms-ole.h.old
	sed -e "s:glib.h:glib-1.2/glib.h:" ms-ole.h.old > ms-ole.h
}

src_compile() {
	econf || die
	emake || die
}

src_install() {
	# prevent executing gtkdoc-fixxref - sandbox violations
	cd "${S}"/doc
	mv Makefile Makefile.orig
	sed 's/gtkdoc-fixxref.*/\\/' Makefile.orig > Makefile

	cd "${S}"
	make DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog NEWS README* TODO
}

pkg_postinst() {
	einfo "Fixing libole2's documentation cross references"
	gtkdoc-fixxref --module=libole2 --html-dir=/usr/share/libole2/html
}
