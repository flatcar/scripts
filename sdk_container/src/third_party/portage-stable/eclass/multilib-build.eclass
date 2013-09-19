# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/multilib-build.eclass,v 1.20 2013/09/17 13:29:19 tommy Exp $

# @ECLASS: multilib-build.eclass
# @MAINTAINER:
# Michał Górny <mgorny@gentoo.org>
# @BLURB: flags and utility functions for building multilib packages
# @DESCRIPTION:
# The multilib-build.eclass exports USE flags and utility functions
# necessary to build packages for multilib in a clean and uniform
# manner.
#
# Please note that dependency specifications for multilib-capable
# dependencies shall use the USE dependency string in ${MULTILIB_USEDEP}
# to properly request multilib enabled.

if [[ ! ${_MULTILIB_BUILD} ]]; then

# EAPI=4 is required for meaningful MULTILIB_USEDEP.
case ${EAPI:-0} in
	4|5) ;;
	*) die "EAPI=${EAPI} is not supported" ;;
esac

inherit multibuild multilib

# @ECLASS-VARIABLE: _MULTILIB_FLAGS
# @INTERNAL
# @DESCRIPTION:
# The list of multilib flags and corresponding ABI values.
_MULTILIB_FLAGS=(
	abi_x86_32:x86
	abi_x86_64:amd64
	abi_x86_x32:x32
	abi_x86_32:x86_fbsd
	abi_x86_64:amd64_fbsd
	abi_mips_n32:n32
	abi_mips_n64:n64
	abi_mips_o32:o32
)

# @ECLASS-VARIABLE: MULTILIB_USEDEP
# @DESCRIPTION:
# The USE-dependency to be used on dependencies (libraries) needing
# to support multilib as well.
#
# Example use:
# @CODE
# RDEPEND="dev-libs/libfoo[${MULTILIB_USEDEP}]
#	net-libs/libbar[ssl,${MULTILIB_USEDEP}]"
# @CODE

_multilib_build_set_globals() {
	local flags=( "${_MULTILIB_FLAGS[@]%:*}" )
	local usedeps=${flags[@]/%/(-)?}

	IUSE=${flags[*]}
	MULTILIB_USEDEP=${usedeps// /,}
}
_multilib_build_set_globals

# @FUNCTION: multilib_get_enabled_abis
# @DESCRIPTION:
# Return the ordered list of enabled ABIs if multilib builds
# are enabled. The best (most preferred) ABI will come last.
#
# If multilib is disabled, the default ABI will be returned
# in order to enforce consistent testing with multilib code.
multilib_get_enabled_abis() {
	debug-print-function ${FUNCNAME} "${@}"

	local abis=( $(get_all_abis) )

	local abi i found
	for abi in "${abis[@]}"; do
		for i in "${_MULTILIB_FLAGS[@]}"; do
			local m_abi=${i#*:}
			local m_flag=${i%:*}

			if [[ ${m_abi} == ${abi} ]] && use "${m_flag}"; then
				echo "${abi}"
				found=1
			fi
		done
	done

	if [[ ! ${found} ]]; then
		# ${ABI} can be used to override the fallback (multilib-portage),
		# ${DEFAULT_ABI} is the safe fallback.
		local abi=${ABI:-${DEFAULT_ABI}}

		debug-print "${FUNCNAME}: no ABIs enabled, fallback to ${abi}"
		debug-print "${FUNCNAME}: ABI=${ABI}, DEFAULT_ABI=${DEFAULT_ABI}"
		echo ${abi}
	fi
}

# @FUNCTION: _multilib_multibuild_wrapper
# @USAGE: <argv>...
# @INTERNAL
# @DESCRIPTION:
# Initialize the environment for ABI selected for multibuild.
_multilib_multibuild_wrapper() {
	debug-print-function ${FUNCNAME} "${@}"

	local ABI=${MULTIBUILD_VARIANT}
	multilib_toolchain_setup "${ABI}"
	"${@}"
}

# @FUNCTION: multilib_foreach_abi
# @USAGE: <argv>...
# @DESCRIPTION:
# If multilib support is enabled, sets the toolchain up for each
# supported ABI along with the ABI variable and correct BUILD_DIR,
# and runs the given commands with them.
#
# If multilib support is disabled, it just runs the commands. No setup
# is done.
multilib_foreach_abi() {
	debug-print-function ${FUNCNAME} "${@}"

	local MULTIBUILD_VARIANTS=( $(multilib_get_enabled_abis) )
	multibuild_foreach_variant _multilib_multibuild_wrapper "${@}"
}

# @FUNCTION: multilib_parallel_foreach_abi
# @USAGE: <argv>...
# @DESCRIPTION:
# If multilib support is enabled, sets the toolchain up for each
# supported ABI along with the ABI variable and correct BUILD_DIR,
# and runs the given commands with them. The commands are run
# in parallel with number of jobs being determined from MAKEOPTS.
#
# If multilib support is disabled, it just runs the commands. No setup
# is done.
#
# Useful for running configure scripts.
multilib_parallel_foreach_abi() {
	debug-print-function ${FUNCNAME} "${@}"

	local MULTIBUILD_VARIANTS=( $(multilib_get_enabled_abis) )
	multibuild_parallel_foreach_variant _multilib_multibuild_wrapper "${@}"
}

# @FUNCTION: multilib_for_best_abi
# @USAGE: <argv>...
# @DESCRIPTION:
# Runs the given command with setup for the 'best' (usually native) ABI.
multilib_for_best_abi() {
	debug-print-function ${FUNCNAME} "${@}"

	local MULTIBUILD_VARIANTS=( $(multilib_get_enabled_abis) )

	multibuild_for_best_variant _multilib_multibuild_wrapper "${@}"
}

# @FUNCTION: multilib_check_headers
# @DESCRIPTION:
# Check whether the header files are consistent between ABIs.
#
# This function needs to be called after each ABI's installation phase.
# It obtains the header file checksums and compares them with previous
# runs (if any). Dies if header files differ.
multilib_check_headers() {
	_multilib_header_cksum() {
		[[ -d ${ED}usr/include ]] && \
		find "${ED}"usr/include -type f \
			-exec cksum {} + | sort -k2
	}

	local cksum=$(_multilib_header_cksum)
	local cksum_file=${T}/.multilib_header_cksum

	if [[ -f ${cksum_file} ]]; then
		local cksum_prev=$(< "${cksum_file}")

		if [[ ${cksum} != ${cksum_prev} ]]; then
			echo "${cksum}" > "${cksum_file}.new"

			eerror "Header files have changed between ABIs."

			if type -p diff &>/dev/null; then
				eerror "$(diff -du "${cksum_file}" "${cksum_file}.new")"
			else
				eerror "Old checksums in: ${cksum_file}"
				eerror "New checksums in: ${cksum_file}.new"
			fi

			die "Header checksum mismatch, aborting."
		fi
	else
		echo "${cksum}" > "${cksum_file}"
	fi
}

# @FUNCTION: multilib_copy_sources
# @DESCRIPTION:
# Create a single copy of the package sources for each enabled ABI.
#
# The sources are always copied from initial BUILD_DIR (or S if unset)
# to ABI-specific build directory matching BUILD_DIR used by
# multilib_foreach_abi().
multilib_copy_sources() {
	debug-print-function ${FUNCNAME} "${@}"

	local MULTIBUILD_VARIANTS=( $(multilib_get_enabled_abis) )
	multibuild_copy_sources
}

# @ECLASS-VARIABLE: MULTILIB_WRAPPED_HEADERS
# @DESCRIPTION:
# A list of headers to wrap for multilib support. The listed headers
# will be moved to a non-standard location and replaced with a file
# including them conditionally to current ABI.
#
# This variable has to be a bash array. Paths shall be relative to
# installation root (${ED}), and name regular files. Recursive wrapping
# is not supported.
#
# Please note that header wrapping is *discouraged*. It is preferred to
# install all headers in a subdirectory of libdir and use pkg-config to
# locate the headers. Some C preprocessors will not work with wrapped
# headers.
#
# Example:
# @CODE
# MULTILIB_WRAPPED_HEADERS=(
#	/usr/include/foobar/config.h
# )
# @CODE

# @FUNCTION: multilib_prepare_wrappers
# @USAGE: [<install-root>]
# @DESCRIPTION:
# Perform the preparation of all kinds of wrappers for the current ABI.
# This function shall be called once per each ABI, after installing
# the files to be wrapped.
#
# Takes an optional custom <install-root> from which files will be
# used. If no root is specified, uses ${ED}.
#
# The files to be wrapped are specified using separate variables,
# e.g. MULTILIB_WRAPPED_HEADERS. Those variables shall not be changed
# between the successive calls to multilib_prepare_wrappers
# and multilib_install_wrappers.
#
# After all wrappers are prepared, multilib_install_wrappers shall
# be called to commit them to the installation tree.
multilib_prepare_wrappers() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${#} -le 1 ]] || die "${FUNCNAME}: too many arguments"

	local root=${1:-${ED}}
	local f

	for f in "${MULTILIB_WRAPPED_HEADERS[@]}"; do
		# drop leading slash if it's there
		f=${f#/}

		if [[ ${f} != usr/include/* ]]; then
			die "Wrapping headers outside of /usr/include is not supported at the moment."
		fi
		# and then usr/include
		f=${f#usr/include}

		local dir=${f%/*}

		if [[ ! -f ${ED}/tmp/multilib-include${f} ]]; then
			dodir "/tmp/multilib-include${dir}"
			# a generic template
			cat > "${ED}/tmp/multilib-include${f}" <<_EOF_
/* This file is auto-generated by multilib-build.eclass
 * as a multilib-friendly wrapper. For the original content,
 * please see the files that are #included below.
 */

#if defined(__x86_64__) /* amd64 */
#	if defined(__ILP32__) /* x32 ABI */
#		error "abi_x86_x32 not supported by the package."
#	else /* 64-bit ABI */
#		error "abi_x86_64 not supported by the package."
#	endif
#elif defined(__i386__) /* plain x86 */
#	error "abi_x86_32 not supported by the package."
#elif defined(__mips__)
#   if(_MIPS_SIM == _ABIN32) /* n32 */
#       error "abi_mips_n32 not supported by the package."
#   elif(_MIPS_SIM == _ABI64) /* n64 */
#       error "abi_mips_n64 not supported by the package."
#   elif(_MIPS_SIM == _ABIO32) /* o32 */
#       error "abi_mips_o32 not supported by the package."
#   endif
#else
#	error "No ABI matched, please report a bug to bugs.gentoo.org"
#endif
_EOF_
		fi

		# Some ABIs may have install less files than others.
		if [[ -f ${root}/usr/include${f} ]]; then
			# $CHOST shall be set by multilib_toolchain_setup
			dodir "/tmp/multilib-include/${CHOST}${dir}"
			mv "${root}/usr/include${f}" "${ED}/tmp/multilib-include/${CHOST}${dir}/" || die

			# XXX: get abi_* directly
			local abi_flag
			case "${ABI}" in
				amd64|amd64_fbsd)
					abi_flag=abi_x86_64;;
				x86|x86_fbsd)
					abi_flag=abi_x86_32;;
				x32)
					abi_flag=abi_x86_x32;;
				n32)
					abi_flag=abi_mips_n32;;
				n64)
					abi_flag=abi_mips_n64;;
				o32)
					abi_flag=abi_mips_o32;;
				*)
					die "Header wrapping for ${ABI} not supported yet";;
			esac

			# Note: match a space afterwards to avoid collision potential.
			sed -e "/${abi_flag} /s&error.*&include <${CHOST}${f}>&" \
				-i "${ED}/tmp/multilib-include${f}" || die
		fi
	done
}

# @FUNCTION: multilib_install_wrappers
# @USAGE: [<install-root>]
# @DESCRIPTION:
# Install the previously-prepared wrappers. This function shall
# be called once, after all wrappers were prepared.
#
# Takes an optional custom <install-root> to which the wrappers will be
# installed. If no root is specified, uses ${ED}. There is no need to
# use the same root as when preparing the wrappers.
#
# The files to be wrapped are specified using separate variables,
# e.g. MULTILIB_WRAPPED_HEADERS. Those variables shall not be changed
# between the calls to multilib_prepare_wrappers
# and multilib_install_wrappers.
multilib_install_wrappers() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${#} -le 1 ]] || die "${FUNCNAME}: too many arguments"

	local root=${1:-${ED}}

	if [[ -d "${ED}"/tmp/multilib-include ]]; then
		multibuild_merge_root \
			"${ED}"/tmp/multilib-include "${root}"/usr/include
		# it can fail if something else uses /tmp
		rmdir "${ED}"/tmp &>/dev/null
	fi
}

# @FUNCTION: multilib_is_native_abi
# @DESCRIPTION:
# Determine whether the currently built ABI is the profile native.
# Return true status (0) if that is true, otherwise false (1).
#
# This is often useful for configure calls when some of the options are
# supposed to be disabled for multilib ABIs (like those used for
# executables only).
multilib_is_native_abi() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${#} -eq 0 ]] || die "${FUNCNAME}: too many arguments"

	[[ ${ABI} == ${DEFAULT_ABI} ]]
}

# @FUNCTION: multilib_build_binaries
# @DESCRIPTION:
# Determine wheter to build binaries for the current build ABI.
# Returns true status (0) if the current built ABI is the profile
# native or COMPLETE_MULTILIB variable is set to yes, otherwise
# false (1).
#
# The COMPLETE_MULTILIB variable can be set by users or profiles
# when they want to build binaries for none-default ABI so e.g.
# 32bit binaries on amd64.
multilib_build_binaries() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${#} -eq 0 ]] || die "${FUNCNAME}: too many arguments"

	[[ ${COMPLETE_MULTILIB} == yes ]] || multilib_is_native_abi
}

_MULTILIB_BUILD=1
fi
