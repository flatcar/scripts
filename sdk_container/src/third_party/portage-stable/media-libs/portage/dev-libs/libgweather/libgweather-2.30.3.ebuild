# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libgweather/libgweather-2.30.3.ebuild,v 1.16 2012/12/19 01:53:47 tetromino Exp $

EAPI="4"
GCONF_DEBUG="no"
GNOME_TARBALL_SUFFIX="bz2"
PYTHON_DEPEND="python? 2"

inherit autotools eutils gnome2 python

DESCRIPTION="Library to access weather information from online services"
HOMEPAGE="https://live.gnome.org/LibGWeather"

LICENSE="GPL-2+"
SLOT="2"
KEYWORDS="alpha amd64 arm ia64 ppc ppc64 sh sparc x86 ~x86-fbsd"
IUSE="python"

# libsoup-gnome is to be used because libsoup[gnome] might not
# get libsoup-gnome installed by the time ${P} is built
RDEPEND=">=x11-libs/gtk+-2.11:2
	>=dev-libs/glib-2.13:2
	>=gnome-base/gconf-2.8:2
	>=net-libs/libsoup-gnome-2.25.1:2.4
	>=dev-libs/libxml2-2.6.0:2
	>=sys-libs/timezone-data-2010k
	python? (
		>=dev-python/pygobject-2:2
		>=dev-python/pygtk-2 )
	!<gnome-base/gnome-applets-2.22.0"
DEPEND="${RDEPEND}
	sys-devel/gettext
	>=dev-util/intltool-0.40.3
	virtual/pkgconfig
	>=dev-util/gtk-doc-am-1.9"

pkg_setup() {
	if use python; then
		python_set_active_version 2
		python_pkg_setup
	fi
}

src_prepare() {
	DOCS="AUTHORS ChangeLog MAINTAINERS NEWS"
	G2CONF="${G2CONF}
		--enable-locations-compression
		--disable-all-translations-in-one-xml
		--disable-static
		$(use_enable python)"

	# Fix building -python, Gnome bug #596660.
	epatch "${FILESDIR}/${PN}-2.30.0-fix-automagic-python-support.patch"

	eautoreconf
	gnome2_src_prepare
}

src_install() {
	gnome2_src_install
	use python && python_clean_installation_image

	find "${D}" -name '*.la' -exec rm -f {} +
}
