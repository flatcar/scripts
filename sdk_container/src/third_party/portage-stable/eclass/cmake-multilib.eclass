# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/cmake-multilib.eclass,v 1.3 2013/09/06 17:11:52 axs Exp $

# @ECLASS: cmake-multilib.eclass
# @MAINTAINER:
# Michał Górny <mgorny@gentoo.org>
# @BLURB: cmake-utils wrapper for multilib builds
# @DESCRIPTION:
# The cmake-multilib.eclass is a cmake-utils.eclass(5) wrapper
# introducing support for building for more than one ABI (multilib).
#
# Inheriting this eclass sets IUSE and exports cmake-utils phase
# function wrappers which build the package for each supported ABI
# if the appropriate flag is enabled.
#
# Note that the multilib support requires out-of-source builds to be
# enabled. Thus, it is impossible to use CMAKE_IN_SOURCE_BUILD with
# it.

# EAPI=5 is required for meaningful MULTILIB_USEDEP.
case ${EAPI:-0} in
	5) ;;
	*) die "EAPI=${EAPI} is not supported" ;;
esac

if [[ ${CMAKE_IN_SOURCE_BUILD} ]]; then
	die "${ECLASS}: multilib support requires out-of-source builds."
fi

inherit cmake-utils multilib-build

EXPORT_FUNCTIONS src_configure src_compile src_test src_install

cmake-multilib_src_configure() {
	multilib_parallel_foreach_abi cmake-utils_src_configure "${@}"
}

cmake-multilib_src_compile() {
	multilib_foreach_abi cmake-utils_src_compile "${@}"
}

cmake-multilib_src_test() {
	multilib_foreach_abi cmake-utils_src_test "${@}"
}

cmake-multilib_src_install() {
	cmake-multilib_secure_install() {
		cmake-utils_src_install "${@}"

		# Make sure all headers are the same for each ABI.
		multilib_prepare_wrappers
		multilib_check_headers
	}

	multilib_foreach_abi cmake-multilib_secure_install "${@}"
	multilib_install_wrappers
}
