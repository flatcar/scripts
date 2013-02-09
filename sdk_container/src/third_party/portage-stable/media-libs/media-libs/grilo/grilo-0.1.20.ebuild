# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/grilo/grilo-0.1.20.ebuild,v 1.8 2013/02/02 22:47:41 ago Exp $

EAPI="4"
GCONF_DEBUG="no" # --enable-debug only changes CFLAGS
GNOME2_LA_PUNT="yes"
VALA_MIN_API_VERSION="0.12"
VALA_MAX_API_VERSION="0.18" # explicitly specified in configure
VALA_USE_DEPEND="vapigen"

inherit gnome2 vala

DESCRIPTION="A framework for easy media discovery and browsing"
HOMEPAGE="https://live.gnome.org/Grilo"

LICENSE="LGPL-2.1+"
SLOT="0.1"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86"
IUSE="doc examples gtk +introspection +network test vala"

RDEPEND="
	>=dev-libs/glib-2.22:2
	dev-libs/libxml2:2
	gtk? ( >=x11-libs/gtk+-3.0:3 )
	introspection? ( >=dev-libs/gobject-introspection-0.9 )
	network? ( >=net-libs/libsoup-2.33.4:2.4 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( >=dev-util/gtk-doc-1.10 )
	vala? ( $(vala_depend) )
	test? (
		dev-python/pygobject:2
		dev-python/pygobject:3
		media-plugins/grilo-plugins:0.1 )"
# eautoreconf requires gnome-common

# Tests fail horribly, but return 0
RESTRICT="test"

pkg_setup() {
	DOCS="AUTHORS NEWS README TODO"
	# --enable-debug only changes CFLAGS, useless for us
	G2CONF="${G2CONF}
		--disable-maintainer-mode
		--disable-static
		--disable-debug
		$(use_enable introspection)
		$(use_enable network grl-net)
		$(use_enable test tests)
		$(use_enable vala)"
}

src_prepare() {
	# Don't build examples
	sed -e '/SUBDIRS/s/examples//' \
		-i Makefile.am -i Makefile.in || die

	# Make test UI optional and avoid eautoreconf
	if ! use gtk; then
		sed -e 's/= grilo-test-ui/= /' \
			-i tools/Makefile.{am,in} || die
	fi

	# Build system doesn't install this file with the tarball
	cp "${FILESDIR}/${PN}-0.1.16-constants.py" "${S}/tests/python/constants.py"

	use vala && vala_src_prepare
	gnome2_src_prepare
}

src_test() {
	cd tests/
	emake check
}

src_install() {
	gnome2_src_install

	# Prevent file collision with other slot
	if use vala; then
		mv "${ED}usr/bin/grilo-simple-playlist" \
			"${ED}usr/bin/grilo-simple-playlist-${SLOT}" || die
	fi

	if use examples; then
		# Install example code
		insinto /usr/share/doc/${PF}/examples
		doins "${S}"/examples/*.c
	fi
}
