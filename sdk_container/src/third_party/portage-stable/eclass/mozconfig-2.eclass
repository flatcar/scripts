# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/mozconfig-2.eclass,v 1.21 2010/01/27 12:06:22 ssuominen Exp $
#
# mozconfig.eclass: the new mozilla.eclass

inherit multilib flag-o-matic mozcoreconf

IUSE="debug gnome ipv6 xinerama"

RDEPEND="x11-libs/libXrender
	x11-libs/libXt
	x11-libs/libXmu
	>=media-libs/jpeg-7
	>=media-libs/libpng-1.2.1
	dev-libs/expat
	app-arch/zip
	app-arch/unzip
	>=x11-libs/gtk+-2.8.6
	>=dev-libs/glib-2.8.2
	>=x11-libs/pango-1.10.1
	>=dev-libs/libIDL-0.8.0
	gnome? ( >=gnome-base/gnome-vfs-2.3.5
		>=gnome-base/libgnomeui-2.2.0 )
	!<x11-base/xorg-x11-6.7.0-r2
	>=x11-libs/cairo-1.0.0"
	#According to bugs #18573, #204520, and couple of others in Mozilla's
	#bugzilla. libmng and mng support has been removed in 2003.


DEPEND="${RDEPEND}
	xinerama? ( x11-proto/xineramaproto )"

mozconfig_config() {
	mozconfig_use_enable ipv6
	mozconfig_use_enable xinerama

	# We use --enable-pango to do truetype fonts, and currently pango
	# is required for it to build
	mozconfig_annotate gentoo --disable-freetype2

	if use debug; then
		mozconfig_annotate +debug \
			--enable-debug \
			--enable-tests \
			--disable-reorder \
			--enable-debugger-info-modules=ALL_MODULES
	else
		mozconfig_annotate -debug \
			--disable-debug \
			--disable-tests \
			--enable-reorder \

		# Currently --enable-elf-dynstr-gc only works for x86 and ppc,
		# thanks to Jason Wever <weeve@gentoo.org> for the fix.
		# -- This breaks now on ppc, no idea why
#		if use x86 || use ppc && [[ ${enable_optimize} != -O0 ]]; then
		if use x86 && [[ ${enable_optimize} != -O0 ]]; then
			mozconfig_annotate "${ARCH} optimized build" --enable-elf-dynstr-gc
		fi
	fi

	if ! use gnome; then
		mozconfig_annotate -gnome --disable-gnomevfs
		mozconfig_annotate -gnome --disable-gnomeui
	fi
}
