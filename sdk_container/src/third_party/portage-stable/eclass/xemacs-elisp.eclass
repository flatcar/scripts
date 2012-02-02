# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/xemacs-elisp.eclass,v 1.2 2007/09/25 18:27:12 graaff Exp $
#
# Copyright 2007 Hans de Graaff <graaff@gentoo.org>
#
# Based on elisp.eclass:
# Copyright 2007 Christian Faulhammer <opfer@gentoo.org>
# Copyright 2002-2003 Matthew Kennedy <mkennedy@gentoo.org>
# Copyright 2003 Jeremy Maitin-Shepard <jbms@attbi.com>
#
# @ECLASS: xemacs-elisp.eclass
# @MAINTAINER:
# xemacs@gentoo.org
# @BLURB: Eclass for XEmacs Lisp packages
# @DESCRIPTION:
#
# Emacs support for other than pure elisp packages is handled by
# xemacs-elisp-common.eclass where you won't have a dependency on XEmacs
# itself.  All elisp-* functions are documented there.
#
# @VARIABLE: SIMPLE_ELISP
# @DESCRIPTION:
# Setting SIMPLE_ELISP=t in an ebuild means, that the package's source
# is a single (in whatever way) compressed elisp file with the file name
# ${PN}-${PV}.  This eclass will then redefine ${S}, and move
# ${PN}-${PV}.el to ${PN}.el in src_unpack().

inherit xemacs-elisp-common

if [ "${SIMPLE_ELISP}" = 't' ]; then
	S="${WORKDIR}/"
fi


DEPEND="app-editors/xemacs"
IUSE=""

xemacs-elisp_src_unpack() {
	unpack ${A}
	if [ "${SIMPLE_ELISP}" = 't' ]
		then
		cd "${S}" && mv ${P}.el ${PN}.el
	fi
}

xemacs-elisp_src_compile() {
	xemacs-elisp-compile *.el
}

xemacs-elisp_src_install () {
	xemacs-elisp-install "${PN}" *.el *.elc
}

EXPORT_FUNCTIONS src_unpack src_compile src_install
