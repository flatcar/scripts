# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/fdo-mime.eclass,v 1.8 2008/12/23 01:28:49 solar Exp $

# @ECLASS: fdo-mime.eclass
# @MAINTAINER: freedesktop-bugs@gentoo.org
#
#
# Original author: foser <foser@gentoo.org>
# @BLURB: Utility eclass to update the desktop mime info as laid out in the freedesktop specs & implementations


# @FUNCTION: fdo-mime_desktop_database_update
# @DESCRIPTION:
# Updates the desktop database.
# Generates a list of mimetypes linked to applications that can handle them
fdo-mime_desktop_database_update() {
	if [ -x "/usr/bin/update-desktop-database" ]
	then
		einfo "Updating desktop mime database ..."
		"/usr/bin/update-desktop-database" -q "${ROOT}/usr/share/applications"
	fi
}

# @FUNCTION: fdo-mime_mime_database_update
# @DESCRIPTION:
# Update the mime database.
# Creates a general list of mime types from several sources
fdo-mime_mime_database_update() {
	if [ -x "/usr/bin/update-mime-database" ]
	then
		einfo "Updating shared mime info database ..."
		"/usr/bin/update-mime-database" "${ROOT}/usr/share/mime"
	fi
}
