# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/pygobject/pygobject-3.2.2-r1.ebuild,v 1.1 2012/12/16 20:57:36 tetromino Exp $

EAPI="5"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"
PYTHON_COMPAT=( python{2_6,2_7,3_1,3_2} )

inherit autotools eutils gnome2 python-r1 virtualx

DESCRIPTION="GLib's GObject library bindings for Python"
HOMEPAGE="http://www.pygtk.org/"

LICENSE="LGPL-2.1+"
SLOT="3"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="+cairo examples test +threads"

REQUIRED_USE="test? ( cairo )"

COMMON_DEPEND=">=dev-libs/glib-2.31.0:2
	>=dev-libs/gobject-introspection-1.31.20
	virtual/libffi:=
	cairo? ( >=dev-python/pycairo-1.10.0 )
	${PYTHON_DEPS}"
# TODO: should be >=dev-python/pycairo-1.10.0[${PYTHON_USEDEP}]
DEPEND="${COMMON_DEPEND}
	x11-libs/cairo[glib]
	virtual/pkgconfig
	test? (
		dev-libs/atk[introspection]
		media-fonts/font-cursor-misc
		media-fonts/font-misc-misc
		x11-libs/gdk-pixbuf:2[introspection]
		x11-libs/gtk+:3[introspection]
		x11-libs/pango[introspection] )"

# We now disable introspection support in slot 2 per upstream recommendation
# (see https://bugzilla.gnome.org/show_bug.cgi?id=642048#c9); however,
# older versions of slot 2 installed their own site-packages/gi, and
# slot 3 will collide with them.
RDEPEND="${COMMON_DEPEND}
	!<dev-python/pygtk-2.13
	!<dev-python/pygobject-2.28.6-r50:2[introspection]"

src_prepare() {
	DOCS="AUTHORS ChangeLog* NEWS README"
	# Hard-enable libffi support since both gobject-introspection and
	# glib-2.29.x rdepend on it anyway
	# docs disabled by upstream default since they are very out of date
	G2CONF="${G2CONF}
		--disable-dependency-tracking
		--with-ffi
		$(use_enable cairo)
		$(use_enable threads thread)"

	# Do not build tests if unneeded, bug #226345
	epatch "${FILESDIR}/${PN}-2.90.1-make_check.patch"

	# Fix cairo-using tests; in 3.4
	epatch "${FILESDIR}/${P}-cairo-tests.patch"
	epatch "${FILESDIR}/${P}-cairo-gobject.patch"

	eautoreconf
	gnome2_src_prepare

	python_copy_sources
}

src_configure() {
	python_foreach_impl run_in_build_dir gnome2_src_configure
}

src_compile() {
	python_foreach_impl run_in_build_dir gnome2_src_compile
}

# FIXME: With python multiple ABI support, tests return 1 even when they pass
src_test() {
	unset DBUS_SESSION_BUS_ADDRESS
	export GIO_USE_VFS="local" # prevents odd issues with deleting ${T}/.gvfs

	testing() {
		export XDG_CACHE_HOME="${T}/${EPYTHON}"
		run_in_build_dir Xemake check
		unset XDG_CACHE_HOME
	}
	python_foreach_impl testing
	unset GIO_USE_VFS
}

src_install() {
	python_foreach_impl run_in_build_dir gnome2_src_install

	if use examples; then
		insinto /usr/share/doc/${PF}
		doins -r examples
	fi
}

run_in_build_dir() {
	pushd "${BUILD_DIR}" > /dev/null || die
	"$@"
	popd > /dev/null
}
