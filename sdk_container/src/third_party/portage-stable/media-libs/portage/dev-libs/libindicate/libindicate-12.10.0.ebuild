# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libindicate/libindicate-12.10.0.ebuild,v 1.1 2012/07/21 18:28:51 ssuominen Exp $

EAPI=4

AYATANA_VALA_VERSION=0.16

inherit autotools eutils flag-o-matic

DESCRIPTION="A library to raise flags on DBus for other components of the desktop to pick up and visualize"
HOMEPAGE="http://launchpad.net/libindicate"
SRC_URI="http://launchpad.net/${PN}/${PV%.*}/${PV}/+download/${P}.tar.gz"

LICENSE="LGPL-2.1 LGPL-3"
SLOT="3"
KEYWORDS="~amd64 ~x86"
IUSE="gtk +introspection"

RESTRICT="test" # consequence of the -no-mono.patch

RDEPEND=">=dev-libs/dbus-glib-0.100
	>=dev-libs/glib-2.30
	>=dev-libs/libdbusmenu-0.6.2:3[gtk?,introspection?]
	dev-libs/libxml2
	gtk? ( >=x11-libs/gtk+-3.2:3 )
	introspection? ( >=dev-libs/gobject-introspection-1 )
	!<${CATEGORY}/${PN}-0.6.1-r201"
EAUTORECONF_DEPEND="dev-util/gtk-doc-am
	gnome-base/gnome-common"
DEPEND="${RDEPEND}
	${EAUTORECONF_DEPEND}
	app-text/gnome-doc-utils
	dev-lang/vala:${AYATANA_VALA_VERSION}[vapigen]
	virtual/pkgconfig"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-0.6.1-no-mono.patch
	sed -i -e "s:vapigen:vapigen-${AYATANA_VALA_VERSION}:" configure.ac || die
	eautoreconf
}

src_configure() {
	append-flags -Wno-error

	# python bindings are only for GTK+-2.x
	econf \
		--docdir=/usr/share/doc/${PF} \
		--disable-silent-rules \
		--disable-static \
		$(use_enable gtk) \
		$(use_enable introspection) \
		--disable-python \
		--disable-scrollkeeper \
		--with-gtk=3 \
		--with-html-dir=/usr/share/doc/${PF}/html
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS ChangeLog NEWS

	nonfatal dosym /usr/share/doc/${PF}/html/${PN} /usr/share/gtk-doc/html/${PN}

	prune_libtool_files
}
