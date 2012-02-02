# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/mozconfig-3.eclass,v 1.8 2010/01/27 12:06:22 ssuominen Exp $
#
# mozconfig.eclass: the new mozilla.eclass

inherit multilib flag-o-matic mozcoreconf-2

IUSE="gnome dbus startup-notification"

RDEPEND="x11-libs/libXrender
	x11-libs/libXt
	x11-libs/libXmu
	>=media-libs/jpeg-7
	dev-libs/expat
	app-arch/zip
	app-arch/unzip
	>=x11-libs/gtk+-2.8.6
	>=dev-libs/glib-2.8.2
	>=x11-libs/pango-1.10.1
	>=dev-libs/libIDL-0.8.0
	gnome? ( >=gnome-base/gnome-vfs-2.16.3
		>=gnome-base/libgnomeui-2.16.1
		>=gnome-base/gconf-2.16.0
		>=gnome-base/libgnome-2.16.0 )
	dbus? ( >=dev-libs/dbus-glib-0.72 )
	startup-notification? ( >=x11-libs/startup-notification-0.8 )
	!<x11-base/xorg-x11-6.7.0-r2
	>=x11-libs/cairo-1.6.0"
	#According to bugs #18573, #204520, and couple of others in Mozilla's
	#bugzilla. libmng and mng support has been removed in 2003.


DEPEND="${RDEPEND}"

mozconfig_config() {
	if ${MN} || ${XUL} || ${TB}; then
	    mozconfig_annotate thebes --enable-default-toolkit=cairo-gtk2
	else
	    mozconfig_annotate -thebes --enable-default-toolkit=gtk2
	fi

	if ! use dbus; then
		mozconfig_annotate '' --disable-dbus
	fi
	mozconfig_use_enable startup-notification

#	if use debug; then
#		mozconfig_annotate +debug \
#			--enable-debug \
#			--enable-tests \
#			--enable-debugger-info-modules=ALL_MODULES
#	else
	mozconfig_annotate -debug \
		--disable-debug \
		--disable-tests

	# Currently --enable-elf-dynstr-gc only works for x86 and ppc,
	# thanks to Jason Wever <weeve@gentoo.org> for the fix.
	# -- This breaks now on ppc, no idea why
#	if use x86 || use ppc && [[ ${enable_optimize} != -O0 ]]; then
	if use x86 && [[ ${enable_optimize} != -O0 ]]; then
		mozconfig_annotate "${ARCH} optimized build" --enable-elf-dynstr-gc
	fi
#	fi

	if ! use gnome; then
		mozconfig_annotate -gnome --disable-gnomevfs
		mozconfig_annotate -gnome --disable-gnomeui
	fi
}
