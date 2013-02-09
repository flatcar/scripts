# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/cogl/cogl-1.12.2.ebuild,v 1.6 2013/02/02 22:47:01 ago Exp $

EAPI="5"
CLUTTER_LA_PUNT="yes"

# Inherit gnome2 after clutter to download sources from gnome.org
inherit eutils clutter gnome2 multilib virtualx

DESCRIPTION="A library for using 3D graphics hardware to draw pretty pictures"
HOMEPAGE="http://www.clutter-project.org/"

LICENSE="LGPL-2.1+ FDL-1.1+"
SLOT="1.0/11"
IUSE="doc examples +introspection +opengl gles2 +pango"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86"

# XXX: need uprof for optional profiling support
COMMON_DEPEND="
	>=dev-libs/glib-2.28.0:2
	x11-libs/cairo:=
	>=x11-libs/gdk-pixbuf-2:2
	x11-libs/libdrm:=
	x11-libs/libX11
	>=x11-libs/libXcomposite-0.4
	x11-libs/libXdamage
	x11-libs/libXext
	>=x11-libs/libXfixes-3
	virtual/opengl
	gles2? ( media-libs/mesa[gles2] )

	introspection? ( >=dev-libs/gobject-introspection-1.34.2 )
	pango? ( >=x11-libs/pango-1.20.0[introspection?] )
"
# before clutter-1.7, cogl was part of clutter
RDEPEND="${COMMON_DEPEND}
	!<media-libs/clutter-1.7"
DEPEND="${COMMON_DEPEND}
	>=dev-util/gtk-doc-am-1.13
	sys-devel/gettext
	virtual/pkgconfig
	doc? ( >=dev-util/gtk-doc-1.13 )
	test? (	app-admin/eselect-opengl
		media-libs/mesa[classic] )
"
# Need classic mesa swrast for tests, llvmpipe causes a test failure

src_configure() {
	# XXX: think about kms-egl, quartz, sdl, wayland
	# Prefer gl over gles2 if both are selected
	gnome2_src_configure \
		--disable-examples-install \
		--disable-profile          \
		--disable-maintainer-flags \
		--enable-cairo             \
		--enable-deprecated        \
		--enable-gdk-pixbuf        \
		--enable-glib              \
		$(use_enable doc gtk-doc)  \
		$(use_enable opengl glx)   \
		$(use_enable opengl gl)    \
		$(use_enable gles2)        \
		$(use_enable gles2 cogl-gles2) \
		$(use_enable gles2 xlib-egl-platform) \
		$(usex gles2 --with-default-driver=$(usex opengl gl gles2)) \
		$(use_enable introspection) \
		$(use_enable pango cogl-pango)
}

src_test() {
	# Use swrast for tests, llvmpipe is incomplete and "test_sub_texture" fails
	# NOTE: recheck if this is needed after every mesa bump
	if [[ "$(eselect opengl show)" != "xorg-x11" ]]; then
		ewarn "Skipping tests because a binary OpenGL library is enabled. To"
		ewarn "run tests for ${PN}, you need to enable the Mesa library:"
		ewarn "# eselect opengl set xorg-x11"
		return
	fi
	LIBGL_DRIVERS_PATH="${EROOT}/usr/$(get_libdir)/mesa" Xemake check
}

src_install() {
	DOCS="NEWS README"
	EXAMPLES="examples/{*.c,*.jpg}"

	clutter_src_install

	# Remove silly examples-data directory
	rm -rvf "${ED}/usr/share/cogl/examples-data/" || die
}

pkg_preinst() {
	gnome2_pkg_preinst
	preserve_old_lib /usr/$(get_libdir)/libcogl.so.9
}

pkg_postinst() {
	gnome2_pkg_postinst
	preserve_old_lib_notify /usr/$(get_libdir)/libcogl.so.9
}
