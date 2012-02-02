# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/bash-completion.eclass,v 1.23 2010/01/02 00:07:46 ulm Exp $

# @ECLASS: bash-completion.eclass
# @MAINTAINER:
# shell-tools@gentoo.org.
#
# Original author: Aaron Walker <ka0ttic@gentoo.org>
# @BLURB: An Interface for installing contributed bash-completion scripts
# @DESCRIPTION:
# Simple eclass that provides an interface for installing
# contributed (ie not included in bash-completion proper)
# bash-completion scripts.

# @ECLASS-VARIABLE: BASH_COMPLETION_NAME
# @DESCRIPTION:
# Install the completion script with this name (see also dobashcompletion)

EXPORT_FUNCTIONS pkg_postinst

IUSE="bash-completion"

# Allow eclass to be inherited by eselect without a circular dependency
if [[ ${CATEGORY}/${PN} != app-admin/eselect ]]; then
	RDEPEND="bash-completion? ( app-admin/eselect )"
fi
PDEPEND="bash-completion? ( app-shells/bash-completion )"

# @FUNCTION: dobashcompletion
# @USAGE: < file > [ new_file ]
# @DESCRIPTION:
# First arg, <file>, is required and is the location of the bash-completion
# script to install.  If the variable BASH_COMPLETION_NAME is set in the
# ebuild, dobashcompletion will install <file> as
# /usr/share/bash-completion/$BASH_COMPLETION_NAME. If it is not set,
# dobashcompletion will check if a second arg [new_file] was passed, installing as
# the specified name.  Failing both these checks, dobashcompletion will
# install the file as /usr/share/bash-completion/${PN}.
dobashcompletion() {
	[[ -z "$1" ]] && die "usage: dobashcompletion <file> <new file>"
	[[ -z "${BASH_COMPLETION_NAME}" ]] && BASH_COMPLETION_NAME="${2:-${PN}}"

	if use bash-completion ; then
		insinto /usr/share/bash-completion
		newins "$1" "${BASH_COMPLETION_NAME}" || die "Failed to install $1"
	fi
}

# @FUNCTION: bash-completion_pkg_postinst
# @DESCRIPTION:
# The bash-completion pkg_postinst function, which is exported
bash-completion_pkg_postinst() {
	if use bash-completion ; then
		elog "In the case that you haven't yet enabled command-line completion"
		elog "for ${PN}, you can run:"
		elog
		elog "  eselect bashcomp enable ${BASH_COMPLETION_NAME:-${PN}}"
		elog
		elog "to install locally, or"
		elog
		elog "  eselect bashcomp enable --global ${BASH_COMPLETION_NAME:-${PN}}"
		elog
		elog "to install system-wide."
	fi
}
