# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-vim/gentoo-syntax/gentoo-syntax-99999999.ebuild,v 1.4 2013/01/27 11:50:39 radhermit Exp $

EAPI=5

inherit vim-plugin git-2

EGIT_REPO_URI="git://git.overlays.gentoo.org/proj/gentoo-syntax.git"

DESCRIPTION="vim plugin: Gentoo Ebuild, Eclass, GLEP, ChangeLog and Portage Files syntax highlighting, filetype and indent settings"
HOMEPAGE="http://git.overlays.gentoo.org/gitweb/?p=proj/gentoo-syntax.git"
unset SRC_URI

LICENSE="vim"
KEYWORDS=""
IUSE="ignore-glep31"

VIM_PLUGIN_HELPFILES="gentoo-syntax"
VIM_PLUGIN_MESSAGES="filetype"

src_prepare() {
	if use ignore-glep31 ; then
		for f in ftplugin/*.vim ; do
			ebegin "Removing UTF-8 rules from ${f} ..."
			sed -i -e 's~\(setlocal fileencoding=utf-8\)~" \1~' ${f} \
				|| die "waah! bad sed voodoo. need more goats."
			eend $?
		done
	fi
}

pkg_postinst() {
	vim-plugin_pkg_postinst

	if ! has_version app-vim/gentoo-syntax ; then
		if use ignore-glep31 1>/dev/null ; then
			ewarn "You have chosen to disable the rules which ensure GLEP 31"
			ewarn "compliance. When editing ebuilds, please make sure you get"
			ewarn "the character set correct."
		else
			elog "Note for developers and anyone else who edits ebuilds:"
			elog "    This release of gentoo-syntax now contains filetype rules to set"
			elog "    fileencoding for ebuilds and ChangeLogs to utf-8 as per GLEP 31."
			elog "    If you find this feature breaks things, please submit a bug and"
			elog "    assign it to vim@gentoo.org. You can use the 'ignore-glep31' USE"
			elog "    flag to remove these rules."
		fi
	fi
}
