# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/grilo/grilo-0.2.3.ebuild,v 1.2 2012/12/10 02:40:29 tetromino Exp $

EAPI="4"
GCONF_DEBUG="no" # --enable-debug only changes CFLAGS
GNOME2_LA_PUNT="yes"
PYTHON_DEPEND="test? 2"
VALA_MIN_API_VERSION="0.12"
VALA_MAX_API_VERSION="0.18" # explicitly specified in configure
VALA_USE_DEPEND="vapigen"

inherit gnome2 vala python

DESCRIPTION="A framework for easy media discovery and browsing"
HOMEPAGE="https://live.gnome.org/Grilo"

LICENSE="LGPL-2.1+"
SLOT="0.2"
KEYWORDS="~amd64 ~x86"
IUSE="gtk examples +introspection +network test vala"
REQUIRED_USE="test? ( introspection )"

RDEPEND=">=dev-libs/glib-2.29.10:2
	dev-libs/libxml2:2
	gtk? ( >=x11-libs/gtk+-3:3 )
	introspection? ( >=dev-libs/gobject-introspection-0.9 )
	network? ( >=net-libs/libsoup-2.33.4:2.4 )"
DEPEND="${RDEPEND}
	>=dev-util/gtk-doc-am-1.10
	virtual/pkgconfig
	vala? ( $(vala_depend) )
	test? (
		dev-python/pygobject:2
		dev-python/pygobject:3
		media-plugins/grilo-plugins:0.2 )"
# eautoreconf requires gnome-common

# Tests fail horribly, but return 0
RESTRICT="test"

pkg_setup() {
	if use test; then
		python_pkg_setup
		python_set_active_version 2
	fi
}

src_prepare() {
	DOCS="AUTHORS NEWS README TODO"
	# --enable-debug only changes CFLAGS, useless for us
	G2CONF="${G2CONF}
		--disable-static
		--disable-debug
		$(use_enable gtk test-ui)
		$(use_enable introspection)
		$(use_enable network grl-net)
		$(use_enable test tests)
		$(use_enable vala)"

	# Don't build examples
	sed -e '/SUBDIRS/s/examples//' \
		-i Makefile.am -i Makefile.in || die

	# Add missing file from tarball
	cp "${FILESDIR}"/${PN}-0.1.16-constants.py \
		tests/python/constants.py || die

	use vala && vala_src_prepare
	gnome2_src_prepare
}

src_test() {
	emake check PYTHON=$(PYTHON -2)
}

src_install() {
	gnome2_src_install
	# Upstream made this conditional on gtk-doc build...
	emake -C doc install DESTDIR="${ED}"

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
