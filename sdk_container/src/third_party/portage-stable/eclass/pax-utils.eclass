# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/pax-utils.eclass,v 1.22 2014/07/11 08:21:58 ulm Exp $

# @ECLASS: pax-utils.eclass
# @MAINTAINER:
# The Gentoo Linux Hardened Team <hardened@gentoo.org>
# @AUTHOR:
# Original Author: Kevin F. Quinn <kevquinn@gentoo.org>
# Modifications for bug #365825, @ ECLASS markup: Anthony G. Basile <blueness@gentoo.org>
# Modifications for bug #431092: Anthony G. Basile <blueness@gentoo.org>
# @BLURB: functions to provide pax markings
# @DESCRIPTION:
#
# This eclass provides support for manipulating PaX markings on ELF binaries,
# whether the system is using legacy PT_PAX markings or the newer XATTR_PAX.
# The eclass wraps the use of paxctl-ng, paxctl, set/getattr and scanelf utilities,
# deciding which to use depending on what's installed on the build host, and
# whether we're working with PT_PAX, XATTR_PAX or both.
#
# To control what markings are made, set PAX_MARKINGS in /etc/portage/make.conf
# to contain either "PT", "XT" or "none".  The default is to attempt both
# PT_PAX and XATTR_PAX.

if [[ -z ${_PAX_UTILS_ECLASS} ]]; then
_PAX_UTILS_ECLASS=1

# @ECLASS-VARIABLE: PAX_MARKINGS
# @DESCRIPTION:
# Control which markings are made:
# PT = PT_PAX markings, XT = XATTR_PAX markings
# Default to PT markings.
PAX_MARKINGS=${PAX_MARKINGS:="PT"}

# @FUNCTION: pax-mark
# @USAGE: <flags> {<ELF files>}
# @RETURN: Shell true if we succeed, shell false otherwise
# @DESCRIPTION:
# Marks <ELF files> with provided PaX <flags>
#
# Flags are passed directly to the utilities unchanged
#
#	p: disable PAGEEXEC		P: enable PAGEEXEC
#	e: disable EMUTRAMP		E: enable EMUTRAMP
#	m: disable MPROTECT		M: enable MPROTECT
#	r: disable RANDMMAP		R: enable RANDMMAP
#	s: disable SEGMEXEC		S: enable SEGMEXEC
#
# Default flags are 'PeMRS', which are the most restrictive settings.  Refer
# to http://pax.grsecurity.net/ for details on what these flags are all about.
#
# Please confirm any relaxation of restrictions with the Gentoo Hardened team.
# Either ask on the gentoo-hardened mailing list, or CC/assign hardened@g.o on
# the bug report.
pax-mark() {

	local f								# loop over paxables
	local flags							# pax flags
	local pt_fail=0 pt_failures=""		# record PT_PAX failures
	local xt_fail=0 xt_failures=""		# record xattr PAX marking failures
	local ret=0							# overal return code of this function

	# Only the actual PaX flags and z are accepted
	# 1. The leading '-' is optional
	# 2. -C -c only make sense for paxctl, but are unnecessary
	#    because we progressively do -q -qc -qC
	# 3. z is allowed for the default

	flags="${1//[!zPpEeMmRrSs]}"
	[[ "${flags}" ]] || return 0
	shift

	# z = default. For XATTR_PAX, the default is no xattr field at all
	local dodefault=""
	[[ "${flags//[!z]}" ]] && dodefault="yes"

	if has PT ${PAX_MARKINGS}; then

		#First try paxctl -> this might try to create/convert program headers
		if type -p paxctl > /dev/null; then
			einfo "PT PaX marking -${flags} with paxctl"
			_pax_list_files einfo "$@"
			for f in "$@"; do
				# First, try modifying the existing PAX_FLAGS header
				paxctl -q${flags} "${f}" && continue
				# Second, try creating a PT_PAX header (works on ET_EXEC)
				# Even though this is less safe, most exes need it, eg bug #463170
				paxctl -qC${flags} "${f}" && continue
				# Third, try stealing the (unused under PaX) PT_GNU_STACK header
				paxctl -qc${flags} "${f}" && continue
				pt_fail=1
				pt_failures="${pt_failures} ${f}"
			done

		#Next try paxctl-ng -> this will not create/convert any program headers
		elif type -p paxctl-ng > /dev/null && paxctl-ng -L ; then
			einfo "PT PaX marking -${flags} with paxctl-ng"
			flags="${flags//z}"
			_pax_list_files einfo "$@"
			for f in "$@"; do
				[[ ${dodefault} == "yes" ]] && paxctl-ng -L -z "${f}"
				[[ "${flags}" ]] || continue
				paxctl-ng -L -${flags} "${f}" && continue
				pt_fail=1
				pt_failures="${pt_failures} ${f}"
			done

		#Finally fall back on scanelf
		elif type -p scanelf > /dev/null && [[ ${PAX_MARKINGS} != "none" ]]; then
			einfo "Fallback PaX marking -${flags} with scanelf"
			_pax_list_files einfo "$@"
			scanelf -Xxz ${flags} "$@"

		#We failed to set PT_PAX flags
		elif [[ ${PAX_MARKINGS} != "none" ]]; then
			pt_failures="$*"
			pt_fail=1
		fi

		if [[ ${pt_fail} == 1 ]]; then
			elog "Failed to set PT_PAX markings -${flags} for:"
			_pax_list_files elog ${pt_failures}
			ret=1
		fi
	fi

	if has XT ${PAX_MARKINGS}; then

		flags="${flags//z}"

		#First try paxctl-ng
		if type -p paxctl-ng > /dev/null && paxctl-ng -l ; then
			einfo "XT PaX marking -${flags} with paxctl-ng"
			_pax_list_files einfo "$@"
			for f in "$@"; do
				[[ ${dodefault} == "yes" ]] && paxctl-ng -d "${f}"
				[[ "${flags}" ]] || continue
				paxctl-ng -l -${flags} "${f}" && continue
				xt_fail=1
				xt_failures="${tx_failures} ${f}"
			done

		#Next try setfattr
		elif type -p setfattr > /dev/null; then
			[[ "${flags//[!Ee]}" ]] || flags+="e" # bug 447150
			einfo "XT PaX marking -${flags} with setfattr"
			_pax_list_files einfo "$@"
			for f in "$@"; do
				[[ ${dodefault} == "yes" ]] && setfattr -x "user.pax.flags" "${f}"
				setfattr -n "user.pax.flags" -v "${flags}" "${f}" && continue
				xt_fail=1
				xt_failures="${tx_failures} ${f}"
			done

		#We failed to set XATTR_PAX flags
		elif [[ ${PAX_MARKINGS} != "none" ]]; then
			xt_failures="$*"
			xt_fail=1
		fi

		if [[ ${xt_fail} == 1 ]]; then
			elog "Failed to set XATTR_PAX markings -${flags} for:"
			_pax_list_files elog ${xt_failures}
			ret=1
		fi
	fi

	# [[ ${ret} == 1 ]] && elog "Executables may be killed by PaX kernels."

	return ${ret}
}

# @FUNCTION: list-paxables
# @USAGE: {<files>}
# @RETURN: Subset of {<files>} which are ELF executables or shared objects
# @DESCRIPTION:
# Print to stdout all of the <files> that are suitable to have PaX flag
# markings, i.e., filter out the ELF executables or shared objects from a list
# of files.  This is useful for passing wild-card lists to pax-mark, although
# in general it is preferable for ebuilds to list precisely which ELFS are to
# be marked.  Often not all the ELF installed by a package need remarking.
# @EXAMPLE:
# pax-mark -m $(list-paxables ${S}/{,usr/}bin/*)
list-paxables() {
	file "$@" 2> /dev/null | grep -E 'ELF.*(executable|shared object)' | sed -e 's/: .*$//'
}

# @FUNCTION: host-is-pax
# @RETURN: Shell true if the build process is PaX enabled, shell false otherwise
# @DESCRIPTION:
# This is intended for use where the build process must be modified conditionally
# depending on whether the host is PaX enabled or not.  It is not intedened to
# determine whether the final binaries need PaX markings.  Note: if procfs is
# not mounted on /proc, this returns shell false (e.g. Gentoo/FBSD).
host-is-pax() {
	grep -qs ^PaX: /proc/self/status
}


# INTERNAL FUNCTIONS
# ------------------
#
# These functions are for use internally by the eclass - do not use
# them elsewhere as they are not supported (i.e. they may be removed
# or their function may change arbitratily).

# Display a list of things, one per line, indented a bit, using the
# display command in $1.
_pax_list_files() {
	local f cmd
	cmd=$1
	shift
	for f in "$@"; do
		${cmd} "     ${f}"
	done
}

fi
