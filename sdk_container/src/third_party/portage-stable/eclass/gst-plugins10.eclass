# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/gst-plugins10.eclass,v 1.2 2006/01/01 01:14:59 swegener Exp $

# Author : foser <foser@gentoo.org>

# gst-plugins eclass
#
# eclass to make external gst-plugins emergable on a per-plugin basis
# to solve the problem with gst-plugins generating far too much unneeded deps
#
# 3rd party applications using gstreamer now should depend on a set of plugins as
# defined in the source, in case of spider usage obtain recommended plugins to use from
# Gentoo developers responsible for gstreamer <gnome@gentoo.org>, the application developer
# or the gstreamer team.

inherit eutils


###
# variable declarations
###

# Create a major/minor combo for our SLOT and executables suffix
PVP=(${PV//[-\._]/ })
#PV_MAJ_MIN=${PVP[0]}.${PVP[1]}
PV_MAJ_MIN=0.10

# Extract the plugin to build from the ebuild name
# May be set by an ebuild and contain more than one indentifier, space seperated
# (only src_configure can handle mutiple plugins at this time)
GST_PLUGINS_BUILD=${PN/gst-plugins-/}

# Actual build dir, is the same as the configure switch name most of the time
GST_PLUGINS_BUILD_DIR=${PN/gst-plugins-/}

# general common gst-plugins ebuild entries
DESCRIPTION="${BUILD_GST_PLUGINS} plugin for gstreamer"
HOMEPAGE="http://gstreamer.freedesktop.org/"
LICENSE="GPL-2"

#SRC_URI="mirror://gnome/sources/gst-plugins/${PV_MAJ_MIN}/${MY_P}.tar.bz2"
SLOT=${PV_MAJ_MIN}
###
# internal functions
###

gst-plugins10_find_plugin_dir() {

	if [ ! -d ${S}/ext/${GST_PLUGINS_BUILD_DIR} ]; then
		if [ ! -d ${S}/sys/${GST_PLUGINS_BUILD_DIR} ]; then
			ewarn "No such plugin directory"
			die
		fi
		einfo "Building system plugin ..."
		cd ${S}/sys/${GST_PLUGINS_BUILD_DIR}
	else
		einfo "Building external plugin ..."
		cd ${S}/ext/${GST_PLUGINS_BUILD_DIR}
	fi

}

###
# public functions
###

gst-plugins10_remove_unversioned_binaries() {

	# remove the unversioned binaries gstreamer provide
	# this is to prevent these binaries to be owned by several SLOTs

	cd ${D}/usr/bin
	for gst_bins in `ls *-${PV_MAJ_MIN}`
	do
		rm ${gst_bins/-${PV_MAJ_MIN}/}
		einfo "Removed ${gst_bins/-${PV_MAJ_MIN}/}"
	done

}

