# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/gnome2.eclass,v 1.86 2009/02/17 16:05:33 dang Exp $

#
# gnome2.eclass
#
# Exports portage base functions used by ebuilds written for packages using the
# GNOME framework. For additional functions, see gnome2-utils.eclass.
#
# Maintained by Gentoo's GNOME herd <gnome@gentoo.org>
#


inherit fdo-mime libtool gnome.org gnome2-utils

case "${EAPI:-0}" in
	0|1)
		EXPORT_FUNCTIONS src_unpack src_compile src_install pkg_preinst pkg_postinst pkg_postrm
		;;
	*)
		EXPORT_FUNCTIONS src_unpack src_prepare src_configure src_compile src_install pkg_preinst pkg_postinst pkg_postrm
		;;
esac

# Extra configure opts passed to econf
G2CONF=${G2CONF:-""}

# Extra options passed to elibtoolize
ELTCONF=${ELTCONF:-""}

# Should we use EINSTALL instead of DESTDIR
USE_EINSTALL=${USE_EINSTALL:-""}

# Run scrollkeeper for this package?
SCROLLKEEPER_UPDATE=${SCROLLKEEPER_UPDATE:-"1"}



if [[ ${GCONF_DEBUG} != "no" ]]; then
	IUSE="debug"
fi



gnome2_src_unpack() {
	unpack ${A}
	cd "${S}"
	has ${EAPI:-0} 0 1 && gnome2_src_prepare
}

gnome2_src_prepare() {
	# Prevent scrollkeeper access violations
	gnome2_omf_fix

	# Run libtoolize
	elibtoolize ${ELTCONF}
}

gnome2_src_configure() {
	# Update the GNOME configuration options
	if [[ ${GCONF_DEBUG} != 'no' ]] ; then
		if use debug ; then
			G2CONF="${G2CONF} --enable-debug=yes"
		fi
	fi

	# Prevent a QA warning
	if has doc ${IUSE} ; then
		G2CONF="${G2CONF} $(use_enable doc gtk-doc)"
	fi

	# Avoid sandbox violations caused by misbehaving packages (bug #128289)
	addwrite "/root/.gnome2"

	# GST_REGISTRY is to work around gst-inspect trying to read/write /root
	GST_REGISTRY="${S}/registry.xml" econf "$@" ${G2CONF} || die "configure failed"
}

gnome2_src_compile() {
	has ${EAPI:-0} 0 1 && gnome2_src_configure "$@"
	emake || die "compile failure"
}

gnome2_src_install() {
	# if this is not present, scrollkeeper-update may segfault and
	# create bogus directories in /var/lib/
	local sk_tmp_dir="/var/lib/scrollkeeper"
	dodir "${sk_tmp_dir}"

	# we must delay gconf schema installation due to sandbox
	export GCONF_DISABLE_MAKEFILE_SCHEMA_INSTALL="1"

	if [[ -z "${USE_EINSTALL}" || "${USE_EINSTALL}" = "0" ]]; then
		debug-print "Installing with 'make install'"
		emake DESTDIR="${D}" "scrollkeeper_localstate_dir=${D}${sk_tmp_dir} " "$@" install || die "install failed"
	else
		debug-print "Installing with 'einstall'"
		einstall "scrollkeeper_localstate_dir=${D}${sk_tmp_dir} " "$@" || die "einstall failed"
	fi

	unset GCONF_DISABLE_MAKEFILE_SCHEMA_INSTALL

	# Manual document installation
	[[ -n "${DOCS}" ]] && dodoc ${DOCS}

	# Do not keep /var/lib/scrollkeeper because:
	# 1. The scrollkeeper database is regenerated at pkg_postinst()
	# 2. ${D}/var/lib/scrollkeeper contains only indexes for the current pkg
	#    thus it makes no sense if pkg_postinst ISN'T run for some reason.
	if [[ -z "$(find "${D}" -name '*.omf')" ]]; then
		export SCROLLKEEPER_UPDATE="0"
	fi
	rm -rf "${D}${sk_tmp_dir}"

	# Make sure this one doesn't get in the portage db
	rm -fr "${D}/usr/share/applications/mimeinfo.cache"
}

gnome2_pkg_preinst() {
	gnome2_gconf_savelist
	gnome2_icon_savelist
}

gnome2_pkg_postinst() {
	gnome2_gconf_install
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update

	if [[ "${SCROLLKEEPER_UPDATE}" = "1" ]]; then
		gnome2_scrollkeeper_update
	fi
}

#gnome2_pkg_prerm() {
#	gnome2_gconf_uninstall
#}

gnome2_pkg_postrm() {
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update

	if [[ "${SCROLLKEEPER_UPDATE}" = "1" ]]; then
		gnome2_scrollkeeper_update
	fi
}

# pkg_prerm
