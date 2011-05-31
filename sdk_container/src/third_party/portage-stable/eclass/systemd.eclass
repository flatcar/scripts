# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/systemd.eclass,v 1.2 2011/05/04 16:02:10 mgorny Exp $

# @ECLASS: systemd.eclass
# @MAINTAINER:
# mgorny@gentoo.org
# @BLURB: helper functions to install systemd units
# @DESCRIPTION:
# This eclass provides a set of functions to install unit files for
# sys-apps/systemd within ebuilds.
# @EXAMPLE:
#
# @CODE
# inherit autotools-utils systemd
# 
# src_configure() {
#	local myeconfargs=(
#		--enable-foo
#		--disable-bar
#	)
#
#	systemd_to_myeconfargs
#	autotools-utils_src_configure
# }
# @CODE

case ${EAPI:-0} in
	0|1|2|3|4) ;;
	*) die "${ECLASS}.eclass API in EAPI ${EAPI} not yet established."
esac

# @FUNCTION: systemd_get_unitdir
# @DESCRIPTION:
# Output the path for the systemd unit directory (not including ${D}).
# This function always succeeds, even if systemd is not installed.
systemd_get_unitdir() {
	debug-print-function ${FUNCNAME} "${@}"

	echo -n /lib/systemd/system
}

# @FUNCTION: systemd_dounit
# @USAGE: unit1 [...]
# @DESCRIPTION:
# Install systemd unit(s). Uses doins, thus it is fatal in EAPI 4
# and non-fatal in earlier EAPIs.
systemd_dounit() {
	debug-print-function ${FUNCNAME} "${@}"

	(
		insinto "$(systemd_get_unitdir)"
		doins "${@}"
	)
}

# @FUNCTION: systemd_enable_service
# @USAGE: target service
# @DESCRIPTION:
# Enable service in desired target, e.g. install a symlink for it.
# Uses dosym, thus it is fatal in EAPI 4 and non-fatal in earlier
# EAPIs.
systemd_enable_service() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${#} -eq 2 ]] || die "Synopsis: systemd_enable_service target service"

	local target=${1}
	local service=${2}
	local ud=$(systemd_get_unitdir)

	dodir "${ud}"/"${target}".wants && \
	dosym ../"${service}" "${ud}"/"${target}".wants
}

# @FUNCTION: systemd_with_unitdir
# @DESCRIPTION:
# Output '--with-systemdsystemunitdir' as expected by systemd-aware configure
# scripts. This function always succeeds. Its output may be quoted in order
# to preserve whitespace in paths. systemd_to_myeconfargs() is preferred over
# this function.
systemd_with_unitdir() {
	debug-print-function ${FUNCNAME} "${@}"

	echo -n --with-systemdsystemunitdir="$(systemd_get_unitdir)"
}

# @FUNCTION: systemd_to_myeconfargs
# @DESCRIPTION:
# Add '--with-systemdsystemunitdir' as expected by systemd-aware configure
# scripts to the myeconfargs variable used by autotools-utils eclass. Handles
# quoting automatically.
systemd_to_myeconfargs() {
	debug-print-function ${FUNCNAME} "${@}"

	myeconfargs=(
		"${myeconfargs[@]}"
		--with-systemdsystemunitdir="$(systemd_get_unitdir)"
	)
}
