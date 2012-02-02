# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/check-reqs.eclass,v 1.6 2008/04/11 13:52:55 zlin Exp $

# @ECLASS: check-reqs.eclass
# @MAINTAINER:
# Bo Ørsted Andresen <zlin@gentoo.org>
# 
# Original Author: Ciaran McCreesh <ciaranm@gentoo.org>
# @BLURB: Provides a uniform way of handling ebuild which have very high build requirements
# @DESCRIPTION:
# This eclass provides a uniform way of handling ebuilds which have very high
# build requirements in terms of memory or disk space. It provides a function
# which should usually be called during pkg_setup().
#
# From a user perspective, the variable CHECKREQS_ACTION can be set to:
#    * "warn" (default), which will display a warning and wait for 15s
#    * "error", which will make the ebuild error out
#    * "ignore", which will not take any action
#
# The chosen action only happens when the system's resources are detected
# correctly and only if they are below the threshold specified by the package.
#
# For ebuild authors: only use this eclass if you reaaalllllly have stupidly
# high build requirements. At an absolute minimum, you shouldn't be using this
# unless the ebuild needs >256MBytes RAM or >1GByte temporary or install space.
# The code should look something like:
#
# @CODE
# pkg_setup() {
#     # values in MBytes
#
#     # need this much memory (does *not* check swap)
#     CHECKREQS_MEMORY="256"
#
#     # need this much temporary build space
#     CHECKREQS_DISK_BUILD="2048"
#
#     # install will need this much space in /usr
#     CHECKREQS_DISK_USR="1024"
#
#     # install will need this much space in /var
#     CHECKREQS_DISK_VAR="1024"
#
#     # go!
#     check_reqs
# }
# @CODE
#
# Alternatively, the check_reqs_conditional function can be used to carry out
# alternate actions (e.g. using a much slower but far less memory intensive
# build option that gives the same end result).
#
# You should *not* override the user's CHECKREQS_ACTION setting, nor should you
# attempt to provide a value if it is unset. Note that the environment variables
# are used rather than parameters for a few reasons:
#   * easier to do if use blah ; then things
#   * we might add in additional requirements things later
# If you don't specify a value for, say, CHECKREQS_MEMORY, then the test is not
# carried out.
#
# These checks should probably mostly work on non-Linux, and they should
# probably degrade gracefully if they don't. Probably.

inherit eutils

# @ECLASS-VARIABLE: CHECKREQS_MEMORY
# @DESCRIPTION:
# How much RAM is needed in MB?

# @ECLASS-VARIABLE:  CHECKREQS_DISK_BUILD
# @DESCRIPTION:
# How much diskspace is needed to build the package? In MB

# @ECLASS-VARIABLE: CHECKREQS_DISK_USR
# @DESCRIPTION:
# How much space in /usr is needed to install the package? In MB

# @ECLASS-VARIABLE: CHECKREQS_DISK_VAR
# @DESCRIPTION:
# How much space is needed in /var? In MB

# @FUNCTION: check_reqs
# @DESCRIPTION:
# Checks the requirements given in the specific variables. If not reached,
# either prints a warning or dies.
check_reqs() {
	[[ -n "${1}" ]] && die "Usage: check_reqs"

	export CHECKREQS_NEED_SLEEP="" CHECKREQS_NEED_DIE=""
	if [[ "$CHECKREQS_ACTION" != "ignore" ]] ; then
		[[ -n "$CHECKREQS_MEMORY" ]] && check_build_memory
		[[ -n "$CHECKREQS_DISK_BUILD" ]] && check_build_disk \
			"${T}" "\${T}" "${CHECKREQS_DISK_BUILD}"
		[[ -n "$CHECKREQS_DISK_USR" ]] && check_build_disk \
			"${ROOT}/usr"  "\${ROOT}/usr" "${CHECKREQS_DISK_USR}"
		[[ -n "$CHECKREQS_DISK_VAR" ]] && check_build_disk \
			"${ROOT}/var"  "\${ROOT}/var" "${CHECKREQS_DISK_VAR}"
	fi

	if [[ -n "${CHECKREQS_NEED_SLEEP}" ]] ; then
		echo
		ewarn "Bad things may happen! You may abort the build by pressing ctrl+c in"
		ewarn "the next 15 seconds."
		ewarn " "
		einfo "To make this kind of warning a fatal error, add a line to /etc/make.conf"
		einfo "setting CHECKREQS_ACTION=\"error\". To skip build requirements checking,"
		einfo "set CHECKREQS_ACTION=\"ignore\"."
		epause 15
	fi

	if [[ -n "${CHECKREQS_NEED_DIE}" ]] ; then
		eerror "Bailing out as specified by CHECKREQS_ACTION"
		die "Build requirements not met"
	fi
}

# @FUNCTION: check_reqs_conditional
# @RETURN: True if requirements check passed, else False
# @DESCRIPTION:
# Checks the requirements given in the specific variables
check_reqs_conditional() {
	[[ -n "${1}" ]] && die "Usage: check_reqs"

	export CHECKREQS_NEED_SLEEP="" CHECKREQS_NEED_DIE=""
	if [[ "$CHECKREQS_ACTION" != "ignore" ]] ; then
		[[ -n "$CHECKREQS_MEMORY" ]] && check_build_memory
		[[ -n "$CHECKREQS_DISK_BUILD" ]] && check_build_disk \
			"${T}" "\${T}" "${CHECKREQS_DISK_BUILD}"
		[[ -n "$CHECKREQS_DISK_USR" ]] && check_build_disk \
			"${ROOT}/usr"  "\${ROOT}/usr" "${CHECKREQS_DISK_USR}"
		[[ -n "$CHECKREQS_DISK_VAR" ]] && check_build_disk \
			"${ROOT}/var"  "\${ROOT}/var" "${CHECKREQS_DISK_VAR}"
	fi

	[[ -z "${CHECKREQS_NEED_SLEEP}" && -z "${CHECKREQS_NEED_DIE}" ]]
}

# internal use only!
check_build_memory() {
	[[ -n "${1}" ]] && die "Usage: check_build_memory"
	check_build_msg_begin "${CHECKREQS_MEMORY}" "MBytes" "RAM"
	if [[ -r /proc/meminfo ]] ; then
		actual_memory=$(sed -n -e '/MemTotal:/s/^[^:]*: *\([0-9]\+\) kB/\1/p' \
			/proc/meminfo)
	else
		actual_memory=$(sysctl hw.physmem 2>/dev/null )
		[[ "$?" == "0" ]] &&
			actual_memory=$(echo $actual_memory | sed -e 's/^[^:=]*[:=]//' )
	fi
	if [[ -n "${actual_memory}" ]] ; then
		if [[ ${actual_memory} -lt $((1024 * ${CHECKREQS_MEMORY})) ]] ; then
			eend 1
			check_build_msg_ick "${CHECKREQS_MEMORY}" "MBytes" "RAM"
		else
			eend 0
		fi
	else
		eend 1
		ewarn "Couldn't determine amount of memory, skipping ..."
	fi
}

# internal use only!
check_build_disk() {
	[[ -z "${3}" ]] && die "Usage: check_build_disk where name needed"
	check_build_msg_begin "${3}" "MBytes" \
			"disk space at ${2}"
	actual_space=$(df -Pm ${1} 2>/dev/null | sed -n \
			'$s/\(\S\+\s\+\)\{3\}\([0-9]\+\).*/\2/p' 2>/dev/null )
	if [[ "$?" == "0" && -n "${actual_space}" ]] ; then
		if [[ ${actual_space} -lt ${3} ]] ; then
			eend 1
			check_build_msg_ick "${3}" "MBytes" \
					"disk space at ${2}"
		else
			eend 0
		fi
	else
		eend 1
		ewarn "Couldn't figure out disk space, skipping ..."
	fi
}

# internal use only!
check_build_msg_begin() {
	ebegin "Checking for at least ${1}${2} ${3}"
}

# internal use only!
check_build_msg_skip() {
	ewarn "Skipping check for at least ${1}${2} ${3}"
}

# internal use only!
check_build_msg_ick() {
	if [[ "${CHECKREQS_ACTION}" == "error" ]] ; then
		eerror "Don't have at least ${1}${2} ${3}"
		echo
		export CHECKREQS_NEED_DIE="yes"
	else
		ewarn "Don't have at least ${1}${2} ${3}"
		echo
		export CHECKREQS_NEED_SLEEP="yes"
	fi
}

