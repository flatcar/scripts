# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gstreamer/gstreamer-0.10.36.ebuild,v 1.10 2013/02/04 00:21:55 ago Exp $

EAPI=4

inherit eutils multilib pax-utils

DESCRIPTION="Streaming media framework"
HOMEPAGE="http://gstreamer.freedesktop.org/"
SRC_URI="http://${PN}.freedesktop.org/src/${PN}/${P}.tar.xz"

LICENSE="LGPL-2+"
SLOT="0.10"
KEYWORDS="~alpha amd64 ~arm ~hppa ia64 ~mips ppc ppc64 ~sh ~sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="+introspection nls +orc test"

RDEPEND=">=dev-libs/glib-2.24:2
	>=dev-libs/libxml2-2.4.9
	introspection? ( >=dev-libs/gobject-introspection-0.6.8 )"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	>=dev-util/gtk-doc-am-1.3
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	nls? ( sys-devel/gettext )"
# gtk-doc-am to install API docs
RDEPEND="${RDEPEND}
	!<media-libs/gst-plugins-base-0.10.26"
	# ^^ queue2 move, mustn't have both libgstcoreleements.so and libgstqueue2.so at runtime providing the element at once

src_prepare() {
	# Disable silly test that's not guaranteed to pass on an arbitrary machine
	epatch "${FILESDIR}/${PN}-0.10.36-disable-test_fail_abstract_new.patch"

	# Disable windows-portability tests that are relevant only on x86 and amd64
	# and can fail on other arches (bug #455038)
	if [[ ${ABI} != x86 && ${ABI} != amd64 ]]; then
		sed -e 's#check:\(.*\)$(CHECK_EXPORTS)#check:\1#' -i Makefile.{am,in} || die
	fi
}

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

	# Remove unversioned binaries to allow SLOT installations in future
	cd "${ED}"/usr/bin || die
	local gst_bins
	for gst_bins in *-${SLOT} ; do
		[[ -e ${gst_bins} ]] || continue
		rm ${gst_bins/-${SLOT}/}
		elog "Removed ${gst_bins/-${SLOT}/}"
	done

	# Punt useless .la files
	prune_libtool_files --modules

	# Needed for orc-using gst plugins on hardened/PaX systems, bug #421579
	use orc && pax-mark -m "${ED}usr/bin/gst-launch-${SLOT}" \
		"${ED}usr/libexec/gstreamer-${SLOT}/gst-plugin-scanner"
}
