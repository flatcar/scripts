# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/pixman/pixman-0.20.2.ebuild,v 1.10 2013/01/31 05:52:41 mattst88 Exp $

EAPI=3
inherit xorg-2 toolchain-funcs versionator

EGIT_REPO_URI="git://anongit.freedesktop.org/git/pixman"
DESCRIPTION="Low-level pixel manipulation routines"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE="altivec mmx neon sse2"

pkg_setup() {
	xorg-2_pkg_setup
	CONFIGURE_OPTIONS="
		$(use_enable altivec vmx)
		$(use_enable neon arm-neon)
		--disable-gtk
		--disable-libpng"

	local enable_mmx="$(use mmx && echo 1 || echo 0)"
	local enable_sse2="$(use sse2 && echo 1 || echo 0)"

	# this block fixes bug #260287
	if use x86; then
		if use sse2 && ! $(version_is_at_least "4.2" "$(gcc-version)"); then
			ewarn "SSE2 instructions require GCC 4.2 or higher."
			ewarn "pixman will be built *without* SSE2 support"
			enable_sse2="0"
		fi
	fi

	# this block fixes bug #236558
	case "$enable_mmx,$enable_sse2" in
	'1,1')
		CONFIGURE_OPTIONS="${CONFIGURE_OPTIONS} --enable-mmx --enable-sse2" ;;
	'1,0')
		CONFIGURE_OPTIONS="${CONFIGURE_OPTIONS} --enable-mmx --disable-sse2" ;;
	'0,1')
		ewarn "You enabled SSE2 but have MMX disabled. This is an invalid."
		ewarn "pixman will be built *without* MMX/SSE2 support."
		CONFIGURE_OPTIONS="${CONFIGURE_OPTIONS} --disable-mmx --disable-sse2" ;;
	'0,0')
		CONFIGURE_OPTIONS="${CONFIGURE_OPTIONS} --disable-mmx --disable-sse2" ;;
	esac
}
