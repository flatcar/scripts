# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/gnome-bluetooth/gnome-bluetooth-2.32.0-r1.ebuild,v 1.8 2012/12/11 21:59:34 ssuominen Exp $

EAPI="4"
GNOME2_LA_PUNT="yes"
GCONF_DEBUG="yes"
GNOME_TARBALL_SUFFIX="bz2"

inherit eutils gnome2 multilib user autotools udev

DESCRIPTION="Fork of bluez-gnome focused on integration with GNOME"
HOMEPAGE="http://live.gnome.org/GnomeBluetooth"
SRC_URI="${SRC_URI} mirror://gentoo/introspection.m4.bz2"

LICENSE="GPL-2+ LGPL-2.1+ FDL-1.1+"
SLOT="2"
KEYWORDS="amd64 ppc x86"
IUSE="doc +introspection nautilus test"

COMMON_DEPEND=">=dev-libs/glib-2.26.1-r1:2
	>=x11-libs/gtk+-2.19.1:2
	>=x11-libs/libnotify-0.4.3
	>=gnome-base/gconf-2.6:2
	>=dev-libs/dbus-glib-0.74
	dev-libs/libunique:1
	nautilus? ( >=gnome-extra/nautilus-sendto-2.31.7 )"
RDEPEND="${COMMON_DEPEND}
	>=net-wireless/bluez-4.34
	app-mobilephone/obexd
	virtual/udev
	introspection? ( >=dev-libs/gobject-introspection-0.6.7 )"
DEPEND="${COMMON_DEPEND}
	!!net-wireless/bluez-gnome
	app-text/docbook-xml-dtd:4.1.2
	app-text/gnome-doc-utils
	app-text/scrollkeeper
	dev-libs/libxml2:2
	dev-util/intltool
	virtual/pkgconfig
	sys-devel/gettext
	x11-libs/libX11
	x11-libs/libXi
	x11-proto/xproto
	doc? ( >=dev-util/gtk-doc-1.9 )
	gnome-base/gnome-common
	dev-util/gtk-doc-am"
# eautoreconf needs:
#	gnome-base/gnome-common
#	dev-util/gtk-doc-am

# Tests are not ready to pass with docs enabled, upstream bug #573392
REQUIRED_USE="test? ( !doc )"

pkg_setup() {
	G2CONF="${G2CONF}
		$(use_enable introspection)
		$(use_enable nautilus nautilus-sendto)
		--disable-moblin
		--disable-desktop-update
		--disable-icon-update
		--disable-schemas-compile"
	DOCS="AUTHORS README NEWS ChangeLog"

	enewgroup plugdev
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-libnotify-0.7.patch

	# Fix build with gobject-introspection 0.9, bug #344227
	epatch "${FILESDIR}"/${P}-introspection-build.patch

	# Fix nautilus-sendto automagic support, upstream bug #639130
	epatch "${FILESDIR}"/${P}-nsd-automagic.patch

	# Add PIN quirk for Magic Trackpad
	epatch "${FILESDIR}"/${P}-pin-quirk.patch

	# wizard: Update DTD for latest addition
	epatch "${FILESDIR}"/${P}-update-dtd.patch

	# wizard: Fix typo in PIN quirks
	epatch "${FILESDIR}"/${P}-fix-typo.patch

	cp "${WORKDIR}"/introspection.m4 . || die
	intltoolize --force --copy --automake || die "intltoolize failed"
	AT_M4DIR="." eautoreconf

	gnome2_src_prepare
}

src_install() {
	gnome2_src_install

	udev_dorules "${FILESDIR}"/80-rfkill.rules
}

pkg_preinst() {
	gnome2_pkg_preinst
	preserve_old_lib /usr/$(get_libdir)/libgnome-bluetooth.so.7
}

pkg_postinst() {
	gnome2_pkg_postinst
	preserve_old_lib_notify /usr/$(get_libdir)/libgnome-bluetooth.so.7

	elog "Don't forget to add yourself to the plugdev group "
	elog "if you want to be able to control bluetooth transmitter."
}
