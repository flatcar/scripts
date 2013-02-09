# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gstreamer/gstreamer-1.0.3.ebuild,v 1.1 2012/12/03 23:26:10 eva Exp $

EAPI=4

inherit eutils multilib pax-utils

DESCRIPTION="Streaming media framework"
HOMEPAGE="http://gstreamer.freedesktop.org/"
SRC_URI="http://${PN}.freedesktop.org/src/${PN}/${P}.tar.xz"

LICENSE="LGPL-2+"
SLOT="1.0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="+introspection nls +orc test"

RDEPEND=">=dev-libs/glib-2.32:2
	introspection? ( >=dev-libs/gobject-introspection-1.31.1 )"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	>=dev-util/gtk-doc-am-1.12
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	nls? ( sys-devel/gettext )"
# gtk-doc-am to install API docs

src_configure() {
	if [[ ${CHOST} == *-interix* ]] ; then
		export ac_cv_lib_dl_dladdr=no
		export ac_cv_func_poll=no
	fi
	if [[ ${CHOST} == powerpc-apple-darwin* ]] ; then
		# GCC groks this, but then refers to an implementation (___multi3,
		# ___udivti3) that don't exist (at least I can't find it), so force
		# this one to be off, such that we use 2x64bit emulation code.
		export gst_cv_uint128_t=no
	fi

	# Disable static archives, dependency tracking and examples
	# to speed up build time
	# Disable debug, as it only affects -g passing (debugging symbols), this must done through make.conf in gentoo
	econf \
		--disable-static \
		$(use_enable nls) \
		--disable-valgrind \
		--disable-examples \
		--disable-debug \
		--enable-check \
		$(use_enable introspection) \
		$(use_enable test tests) \
		--with-package-name="GStreamer ebuild for Gentoo" \
		--with-package-origin="http://packages.gentoo.org/package/media-libs/gstreamer"
}

src_install() {
	DOCS="AUTHORS ChangeLog NEWS MAINTAINERS README RELEASE"
	default

	# Punt useless .la files
	prune_libtool_files --modules

	# Needed for orc-using gst plugins on hardened/PaX systems, bug #421579
	use orc && pax-mark -m "${ED}usr/bin/gst-launch-${SLOT}" \
		"${ED}usr/libexec/gstreamer-${SLOT}/gst-plugin-scanner"
}
