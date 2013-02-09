# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gst-rtsp-server/gst-rtsp-server-0.10.8.ebuild,v 1.9 2012/11/07 20:37:33 tetromino Exp $

EAPI=3

PYTHON_DEPEND="2"
inherit python

DESCRIPTION="A GStreamer based RTSP server"
HOMEPAGE="http://people.freedesktop.org/~wtay/"
SRC_URI="http://people.freedesktop.org/~wtay/${P/-server/}.tar.bz2"

LICENSE="GPL-2"
SLOT="0.10"
KEYWORDS="amd64 x86"
IUSE="debug doc +introspection nls static-libs vala"
S="${WORKDIR}/${P/-server/}"

# ./configure is broken, so PYGOBJECT_REQ must be defined
PYGOBJECT_REQ=2.11.2

RDEPEND="
	>=dev-libs/glib-2.10.0:2
	dev-libs/libxml2
	>=dev-python/pygobject-${PYGOBJECT_REQ}:2
	dev-python/gst-python:0.10
	introspection? ( >=dev-libs/gobject-introspection-0.6.3 )
	>=media-libs/gstreamer-0.10.29:0.10[introspection?]
	>=media-libs/gst-plugins-base-0.10.29:0.10[introspection?]
	vala? ( dev-lang/vala )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( >=dev-util/gtk-doc-1.3 )
	nls? ( >=sys-devel/gettext-0.17 )"

pkg_setup() {
	python_set_active_version 2
}

src_configure() {
	econf \
		--with-package-origin="http://www.gentoo.org" \
		$(use_enable debug) \
		$(use_enable doc gtk-doc) \
		$(use_enable nls) \
		$(use_enable introspection) \
		$(use_enable static-libs static) \
		$(use_enable vala) \
		PYGOBJECT_REQ=${PYGOBJECT_REQ}
}

src_install() {
	dodoc AUTHORS TODO
	emake install DESTDIR="${D}"
}
