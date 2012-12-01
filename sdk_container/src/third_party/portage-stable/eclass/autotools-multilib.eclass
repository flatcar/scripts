# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/autotools-multilib.eclass,v 1.1 2012/10/08 18:44:30 mgorny Exp $

# @ECLASS: autotools-multilib.eclass
# @MAINTAINER:
# Michał Górny <mgorny@gentoo.org>
# @BLURB: autotools-utils wrapper for multilib builds
# @DESCRIPTION:
# The autotools-multilib.eclass is an autotools-utils.eclass(5) wrapper
# introducing support for building for more than one ABI (multilib).
#
# Inheriting this eclass sets IUSE=multilib and exports autotools-utils
# phase function wrappers which build the package for each supported ABI
# if the flag is enabled. Otherwise, it works like regular
# autotools-utils.
#
# Note that the multilib support requires out-of-source builds to be
# enabled. Thus, it is impossible to use AUTOTOOLS_IN_SOURCE_BUILD with
# it.

case ${EAPI:-0} in
	2|3|4) ;;
	*) die "EAPI=${EAPI} is not supported" ;;
esac

if [[ ${AUTOTOOLS_IN_SOURCE_BUILD} ]]; then
	die "${ECLASS}: multilib support requires out-of-source builds."
fi

inherit autotools-utils multilib

EXPORT_FUNCTIONS src_configure src_compile src_test src_install

IUSE=multilib

# @FUNCTION: autotools-multilib_foreach_abi
# @USAGE: argv...
# @DESCRIPTION:
# If multilib support is enabled, sets the toolchain up for each
# supported ABI along with the ABI variable and correct
# AUTOTOOLS_BUILD_DIR, and runs the given commands with them.
#
# If multilib support is disabled, it just runs the commands. No setup
# is done.
autotools-multilib_foreach_abi() {
	if use multilib; then
		local ABI
		for ABI in $(get_all_abis); do
			multilib_toolchain_setup "${ABI}"
			AUTOTOOLS_BUILD_DIR=${S%%/}-${ABI} "${@}"
		done
	else
		"${@}"
	fi
}

autotools-multilib_src_configure() {
	autotools-multilib_foreach_abi autotools-utils_src_configure
}

autotools-multilib_src_compile() {
	autotools-multilib_foreach_abi autotools-utils_src_compile
}

autotools-multilib_src_test() {
	autotools-multilib_foreach_abi autotools-utils_src_test
}

autotools-multilib_src_install() {
	autotools-multilib_foreach_abi autotools-utils_src_install
}
