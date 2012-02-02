# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/gst-plugins.eclass,v 1.35 2009/11/30 04:19:36 abcd Exp $

# @DEAD
# To be removed on 2011/11/30.
ewarn "Please fix your package (${CATEGORY}/${PF}) to not use ${ECLASS}.eclass"

PVP=(${PV//[-\._]/ })
PV_MAJ_MIN=${PVP[0]}.${PVP[1]}
SLOT=${PV_MAJ_MIN}

gst-plugins_pkg_postrm() {
	gst-register-${SLOT}
}

EXPORT_FUNCTIONS pkg_postrm
