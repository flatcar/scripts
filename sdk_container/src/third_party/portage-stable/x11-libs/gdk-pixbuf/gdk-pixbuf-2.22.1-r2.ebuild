# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/gdk-pixbuf/gdk-pixbuf-2.22.1-r2.ebuild,v 1.8 2011/10/03 08:54:19 lxnay Exp $

EAPI="3"

inherit gnome.org multilib libtool autotools

DESCRIPTION="Image loading library for GTK+"
HOMEPAGE="http://www.gtk.org/"

LICENSE="LGPL-2"
SLOT="2"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="+X debug doc +introspection jpeg jpeg2k svg tiff test"

# librsvg blocker is for the new pixbuf loader API, you lose icons otherwise
RDEPEND="
	>=dev-libs/glib-2.25.15
	>=media-libs/libpng-1.2.44
	introspection? ( >=dev-libs/gobject-introspection-0.9.3 )
	jpeg? ( virtual/jpeg )
	jpeg2k? ( media-libs/jasper )
	tiff? ( >=media-libs/tiff-3.9.2 )
	X? ( x11-libs/libX11 )
	!<gnome-base/gail-1000
	!<gnome-base/librsvg-2.31.0
	!<x11-libs/gtk+-2.21.3:2
	!<x11-libs/gtk+-2.90.4:3"
DEPEND="${RDEPEND}
	>=dev-util/pkgconfig-0.9
	>=sys-devel/gettext-0.17
	>=dev-util/gtk-doc-am-1.11
	doc? (
		>=dev-util/gtk-doc-1.11
		~app-text/docbook-xml-dtd-4.1.2 )"
# Needed as reported in bug #363715
PDEPEND="svg? ( gnome-base/librsvg )"

src_prepare() {
	# Only build against libX11 if the user wants to do so
	epatch "${FILESDIR}"/${PN}-2.21.4-fix-automagic-x11.patch

	# Fix libpng-1.5 compatibility, bug 354557 — taken from upstream
	epatch "${FILESDIR}/${P}-fix-libpng15.patch"

	# GIF: Don't return a partially initialized pixbuf structure
	epatch "${FILESDIR}/${P}-CVE-2011-2485.patch"

	elibtoolize
	eautoreconf
}

src_configure() {
	# png always on to display icons (foser)
	local myconf="
		$(use_enable doc gtk-doc)
		$(use_with jpeg libjpeg)
		$(use_with jpeg2k libjasper)
		$(use_with tiff libtiff)
		$(use_enable introspection)
		$(use_with X x11)
		--with-libpng"

	# Passing --disable-debug is not recommended for production use
	use debug && myconf="${myconf} --enable-debug=yes"

	econf ${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die

	dodoc AUTHORS NEWS* README* || die

	find "${ED}" -name '*.la' -exec rm -f {} +
}

pkg_postinst() {
	# causes segfault if set, see bug 375615
	unset __GL_NO_DSO_FINALIZER

	tmp_file=$(mktemp --suffix=gdk_pixbuf_ebuild)
	# be atomic!
	gdk-pixbuf-query-loaders > "${tmp_file}"
	if [ "${?}" = "0" ]; then
		cat "${tmp_file}" > "${EROOT}usr/$(get_libdir)/gdk-pixbuf-2.0/2.10.0/loaders.cache"
	fi
	rm "${tmp_file}"

	if [ -e "${EROOT}"usr/lib/gtk-2.0/2.*/loaders ]; then
		elog "You need to rebuild ebuilds that installed into" "${EROOT}"usr/lib/gtk-2.0/2.*/loaders
		elog "to do that you can use qfile from portage-utils:"
		elog "emerge -va1 \$(qfile -qC ${EPREFIX}/usr/lib/gtk-2.0/2.*/loaders)"
	fi
}
