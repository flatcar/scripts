# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libmirage/libmirage-2.0.0.ebuild,v 1.3 2013/02/02 22:03:29 tetromino Exp $

EAPI="5"

CMAKE_MIN_VERSION="2.8.5"

inherit cmake-utils eutils fdo-mime toolchain-funcs versionator

DESCRIPTION="CD and DVD image access library"
HOMEPAGE="http://cdemu.org"
SRC_URI="mirror://sourceforge/cdemu/${P}.tar.bz2"

LICENSE="GPL-2+"
SLOT="0/7" # subslot = libmirage soname version
KEYWORDS="~amd64 ~hppa ~x86"
IUSE="doc +introspection"

RDEPEND=">=app-arch/bzip2-1:=
	>=app-arch/xz-utils-5:=
	>=dev-libs/glib-2.24:2
	>=media-libs/libsndfile-1.0:=
	sys-libs/zlib:=
	introspection? ( >=dev-libs/gobject-introspection-1.30 )"
DEPEND="${RDEPEND}
	dev-util/desktop-file-utils
	virtual/pkgconfig
	doc? ( dev-util/gtk-doc )"

pkg_pretend() {
	check_compiler
}

pkg_setup() {
	check_compiler
}

src_prepare() {
	# Make sure gtk-doc and gobject-introspection are optional
	# https://sourceforge.net/p/cdemu/patches/16/
	epatch "${FILESDIR}/${PN}-2.0.0-gtk-doc.patch"

	sed -e 's/-DG_DISABLE_DEPRECATED//' -i CMakeLists.txt || die
}

src_configure() {
	local mycmakeargs=(
		$(cmake-utils_use doc GTKDOC_ENABLED)
		$(cmake-utils_use introspection INTROSPECTION_ENABLED)
	)
	cmake-utils_src_configure
}

src_install() {
	DOCS="AUTHORS README"
	cmake-utils_src_install
	prune_libtool_files --modules
}

pkg_postinst() {
	fdo-mime_mime_database_update
}

pkg_postrm() {
	fdo-mime_mime_database_update
}

check_compiler() {
	[[ ${MERGE_TYPE} == binary ]] && return

	local v=$(gcc-version)
	[[ ${v} ]] && ! version_is_at_least 4.6 "${v}" &&
		die "${P} requires gcc-4.6 or higher to build. Please install a recent
version of sys-devel/gcc, and set it as the system compiler using gcc-config"
}
