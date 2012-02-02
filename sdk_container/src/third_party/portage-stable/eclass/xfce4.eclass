# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/xfce4.eclass,v 1.33 2009/11/30 04:19:36 abcd Exp $

# @DEAD
# To be removed on 2011/09/30.
ewarn "Please fix your package (${CATEGORY}/${PF}) to not use ${ECLASS}.eclass"

xfce4_pkg_postrm() {
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update
}

EXPORT_FUNCTIONS pkg_postrm
