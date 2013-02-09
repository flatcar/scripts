# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libgpod/libgpod-0.8.2.ebuild,v 1.9 2013/02/03 16:34:39 ssuominen Exp $

EAPI=4

PYTHON_DEPEND="python? 2:2.6"

inherit eutils mono python toolchain-funcs

DESCRIPTION="Shared library to access the contents of an iPod"
HOMEPAGE="http://www.gtkpod.org/libgpod/"
SRC_URI="mirror://sourceforge/gtkpod/${P}.tar.bz2"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="+gtk python +udev ios mono static-libs"

RDEPEND=">=app-pda/libplist-1.0
	>=dev-db/sqlite-3
	>=dev-libs/glib-2.16:2
	dev-libs/libxml2
	sys-apps/sg3_utils
	gtk? ( x11-libs/gdk-pixbuf:2 )
	ios? ( app-pda/libimobiledevice )
	python? (
		>=media-libs/mutagen-1.8
		>=dev-python/pygobject-2.8:2
		)
	udev? ( virtual/udev )
	mono? (
		>=dev-lang/mono-1.9.1
		>=dev-dotnet/gtk-sharp-2.12
		)"
DEPEND="${RDEPEND}
	python? ( >=dev-lang/swig-1.3.24 )
	dev-libs/libxslt
	dev-util/intltool
	sys-devel/gettext
	virtual/pkgconfig"

DOCS="AUTHORS NEWS README* TROUBLESHOOTING"

pkg_setup() {
	if use python; then
		python_set_active_version 2
		python_pkg_setup
	fi
}

src_prepare() {
	>py-compile
}

src_configure() {
	local udevdir=/lib/udev
	use udev && udevdir="$($(tc-getPKG_CONFIG) --variable=udevdir udev)"

	econf \
		$(use_enable static-libs static) \
		$(use_enable udev) \
		$(use_enable gtk gdk-pixbuf) \
		$(use_enable python pygobject) \
		--without-hal \
		$(use_with ios libimobiledevice) \
		--with-udev-dir="${udevdir}" \
		--with-html-dir=/usr/share/doc/${PF}/html \
		$(use_with python) \
		$(use_with mono)
}

src_install() {
	default
	prune_libtool_files --all
}

pkg_postinst() {
	use python && python_mod_optimize gpod
}

pkg_postrm() {
	use python && python_mod_cleanup gpod
}
