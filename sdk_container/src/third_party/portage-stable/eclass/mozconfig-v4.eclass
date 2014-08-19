# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/mozconfig-v4.eclass,v 1.3 2014/08/01 16:32:16 axs Exp $
#
# mozconfig-v4.eclass: the new mozilla.eclass

inherit multilib flag-o-matic mozcoreconf-2

# @ECLASS-VARIABLE: MOZCONFIG_OPTIONAL_WIFI
# @DESCRIPTION:
# Set this variable before the inherit line, when an ebuild needs to provide
# optional necko-wifi support via IUSE="wifi".  Currently this would include
# ebuilds for firefox, and potentially seamonkey.
#
# Leave the variable UNSET if necko-wifi support should not be available.

# @FUNCTION: mozconfig_config
# @DESCRIPTION:
# Set common configure options for mozilla packages.
# Call this within src_configure() phase, after mozconfig_init
#
# Example:
#
# inherit mozconfig-v4
#
# src_configure() {
# 	mozconfig_init
# 	mozconfig_config
#	# ... misc ebuild-unique settings via calls to
#	# ... mozconfig_{annotate,use_with,use_enable}
#	mozconfig_final
# }

# use-flags common among all mozilla ebuilds
IUSE="dbus debug startup-notification"

RDEPEND=">=app-text/hunspell-1.2
	dev-libs/expat
	>=dev-libs/libevent-1.4.7
	>=x11-libs/cairo-1.12[X]
	>=x11-libs/gtk+-2.10:2
	>=x11-libs/pango-1.22.0
	kernel_linux? ( media-libs/alsa-lib )
	virtual/freedesktop-icon-theme
	dbus? ( >=dev-libs/dbus-glib-0.72 )
	startup-notification? ( >=x11-libs/startup-notification-0.8 )
	>=dev-libs/glib-2.26:2"

if [[ -n ${MOZCONFIG_OPTIONAL_WIFI} ]]; then
IUSE+=" wifi"
RDEPEND+="
	wifi? ( >=sys-apps/dbus-0.60
		>=dev-libs/dbus-glib-0.72
		net-wireless/wireless-tools )"
fi

DEPEND="app-arch/zip
	app-arch/unzip
	${RDEPEND}"

mozconfig_config() {

	mozconfig_annotate '' --enable-default-toolkit=cairo-gtk2

	if has bindist ${IUSE}; then
		mozconfig_use_enable !bindist official-branding
		if [[ ${PN} == firefox ]] && use bindist ; then
			mozconfig_annotate '' --with-branding=browser/branding/aurora
		fi
	fi

	mozconfig_use_enable debug
	mozconfig_use_enable debug tests

	if ! use debug ; then
		mozconfig_annotate 'disabled by Gentoo' --disable-debug-symbols
	fi

	mozconfig_use_enable startup-notification

	if has wifi ${IUSE} ; then
		# wifi pulls in dbus so manage both here
		mozconfig_use_enable wifi necko-wifi
		if use wifi && ! use dbus; then
			echo "Enabling dbus support due to wifi request"
			mozconfig_annotate 'dbus required by necko-wifi' --enable-dbus
		else
			mozconfig_use_enable dbus
		fi
	else
		mozconfig_use_enable dbus
		mozconfig_annotate 'disabled' --disable-necko-wifi
	fi

	mozconfig_annotate 'required' --enable-ogg
	mozconfig_annotate 'required' --enable-wave

	if has jit ${IUSE}; then
		mozconfig_use_enable jit ion
		mozconfig_use_enable jit yarr-jit
	fi

	# These are enabled by default in all mozilla applications
	mozconfig_annotate '' --with-system-nspr --with-nspr-prefix="${EPREFIX}"/usr
	mozconfig_annotate '' --with-system-nss --with-nss-prefix="${EPREFIX}"/usr
	mozconfig_annotate '' --x-includes="${EPREFIX}"/usr/include --x-libraries="${EPREFIX}"/usr/$(get_libdir)
	mozconfig_annotate '' --with-system-libevent="${EPREFIX}"/usr
	mozconfig_annotate '' --enable-system-hunspell
	mozconfig_annotate '' --disable-gnomevfs
	mozconfig_annotate '' --disable-gnomeui
	mozconfig_annotate '' --enable-gio
	mozconfig_annotate '' --disable-crashreporter
}
