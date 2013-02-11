# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/gmime/gmime-2.6.10.ebuild,v 1.9 2012/10/28 15:40:48 armin76 Exp $

EAPI="4"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"

inherit gnome2 eutils mono

DESCRIPTION="Utilities for creating and parsing messages using MIME"
HOMEPAGE="http://spruce.sourceforge.net/gmime/ http://developer.gnome.org/gmime/stable/"

SLOT="2.6"
LICENSE="LGPL-2.1"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE="doc mono static-libs"

RDEPEND=">=dev-libs/glib-2.18.0:2
	sys-libs/zlib
	>=app-crypt/gpgme-1.1.6
	mono? (
		dev-lang/mono
		>=dev-dotnet/glib-sharp-2.4.0:2 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? (
		>=dev-util/gtk-doc-1.8
		app-text/docbook-sgml-utils )
	mono? ( dev-dotnet/gtk-sharp-gapi:2 )"

#	dev-util/gtk-doc-am"
# eautoreconf requires dev-util/gtk-doc-am

pkg_setup() {
	DOCS="AUTHORS ChangeLog NEWS PORTING README TODO"
	G2CONF="${G2CONF}
		--enable-cryptography
		--disable-strict-parser
		$(use_enable mono)
		$(use_enable static-libs static)"
}

src_compile() {
	MONO_PATH="${S}" gnome2_src_compile
	if use doc; then
		emake -C docs/tutorial html
	fi
}

src_install() {
	GACUTIL_FLAGS="/root '${ED}/usr/$(get_libdir)' /gacdir '${EPREFIX}/usr/$(get_libdir)' /package ${PN}" \
		gnome2_src_install

	if use doc ; then
		# we don't use docinto/dodoc, because we don't want html doc gzipped
		insinto /usr/share/doc/${PF}/tutorial
		doins docs/tutorial/html/*
	fi
}
