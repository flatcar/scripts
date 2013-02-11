# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/goocanvas/goocanvas-2.0.1.ebuild,v 1.10 2012/05/28 14:03:35 armin76 Exp $

EAPI="4"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"
PYTHON_DEPEND="python? 2:2.6"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="2.[45] 3.* *-jython"

inherit eutils gnome2 python

DESCRIPTION="Canvas widget for GTK+ using the cairo 2D library for drawing"
HOMEPAGE="http://live.gnome.org/GooCanvas"

LICENSE="GPL-2"
SLOT="2.0"
KEYWORDS="alpha amd64 ia64 ppc ppc64 sparc x86 ~x86-fbsd"
IUSE="doc examples +introspection python"

# python only enables python specific binding override
RDEPEND=">=x11-libs/gtk+-3.0.0:3
	>=dev-libs/glib-2.28.0:2
	>=x11-libs/cairo-1.10.0
	introspection? ( >=dev-libs/gobject-introspection-0.6.7 )
	python? ( >=dev-python/pygobject-2.28 )
"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( >=dev-util/gtk-doc-1.8 )"

pkg_setup() {
	DOCS="AUTHORS ChangeLog NEWS README TODO"
	G2CONF="${G2CONF}
		--disable-rebuilds
		--disable-static
		$(use_enable introspection)
		$(use_enable python)"

	if use python; then
		python_pkg_setup
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-gold.patch
	# Do not build demos
	sed -e 's/^\(SUBDIRS =.*\)demo\(.*\)$/\1\2/' \
		-i Makefile.am Makefile.in || die "sed failed"

	# Python bindings are built/installed manually.
	sed -e "/SUBDIRS = python/d" -i bindings/Makefile.am bindings/Makefile.in

	# disable pyc compiling
	>py-compile

	gnome2_src_prepare
}

src_compile() {
	gnome2_src_compile

	if use python; then
		python_copy_sources bindings/python
		python_execute_function -s -d --source-dir bindings/python
	fi
}

src_install() {
	gnome2_src_install

	if use python; then
		python_execute_function -s -d --source-dir bindings/python
		python_clean_installation_image
	fi

	if use examples; then
		insinto "/usr/share/doc/${P}/examples/"
		doins demo/*.[ch] demo/*.png
	fi
}
