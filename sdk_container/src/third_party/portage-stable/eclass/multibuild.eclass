# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/multibuild.eclass,v 1.14 2013/09/18 08:49:33 mgorny Exp $

# @ECLASS: multibuild
# @MAINTAINER:
# Michał Górny <mgorny@gentoo.org>
# @AUTHOR:
# Author: Michał Górny <mgorny@gentoo.org>
# @BLURB: A generic eclass for building multiple variants of packages.
# @DESCRIPTION:
# The multibuild eclass aims to provide a generic framework for building
# multiple 'variants' of a package (e.g. multilib, Python
# implementations).

case "${EAPI:-0}" in
	0|1|2|3)
		die "Unsupported EAPI=${EAPI:-0} (too old) for ${ECLASS}"
		;;
	4|5)
		;;
	*)
		die "Unsupported EAPI=${EAPI} (unknown) for ${ECLASS}"
		;;
esac

if [[ ! ${_MULTIBUILD} ]]; then

inherit multiprocessing

DEPEND="userland_GNU? ( >=sys-apps/coreutils-8.5 )"

# @ECLASS-VARIABLE: MULTIBUILD_VARIANTS
# @DESCRIPTION:
# An array specifying all enabled variants which multibuild_foreach*
# can execute the process for.
#
# In ebuild, it can be set in global scope. Eclasses should set it
# locally in function scope to support nesting properly.
#
# Example:
# @CODE
# python_foreach_impl() {
#	local MULTIBUILD_VARIANTS=( python{2_5,2_6,2_7} ... )
#	multibuild_foreach_variant python_compile
# }
# @CODE

# @ECLASS-VARIABLE: MULTIBUILD_VARIANT
# @DESCRIPTION:
# The current variant which the function was executed for.
#
# Example value:
# @CODE
# python2_6
# @CODE

# @ECLASS-VARIABLE: MULTIBUILD_ID
# @DESCRIPTION:
# The unique identifier for a multibuild run. In a simple run, it is
# equal to MULTIBUILD_VARIANT. In a nested multibuild environment, it
# contains the complete selection tree.
#
# It can be used to create variant-unique directories and files.
#
# Example value:
# @CODE
# amd64-double
# @CODE

# @ECLASS-VARIABLE: BUILD_DIR
# @DESCRIPTION:
# The current build directory. In global scope, it is supposed
# to contain an 'initial' build directory. If unset, ${S} is used.
#
# multibuild_foreach_variant() sets BUILD_DIR locally
# to variant-specific build directories based on the initial value
# of BUILD_DIR.
#
# Example value:
# @CODE
# ${WORKDIR}/foo-1.3-python2_6
# @CODE

# @FUNCTION: multibuild_foreach_variant
# @USAGE: [<argv>...]
# @DESCRIPTION:
# Run the passed command repeatedly for each of the enabled package
# variants.
#
# Each of the runs will have variant-specific BUILD_DIR set, and output
# teed to a separate log in ${T}.
#
# The function returns 0 if all commands return 0, or the first non-zero
# exit status otherwise. However, it performs all the invocations
# nevertheless. It is preferred to call 'die' inside of the passed
# function.
multibuild_foreach_variant() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${MULTIBUILD_VARIANTS} ]] \
		|| die "MULTIBUILD_VARIANTS need to be set"

	local bdir=${BUILD_DIR:-${S}}

	# Avoid writing outside WORKDIR if S=${WORKDIR}.
	[[ ${bdir%%/} == ${WORKDIR%%/} ]] && bdir=${WORKDIR}/build

	local prev_id=${MULTIBUILD_ID:+${MULTIBUILD_ID}-}
	local ret=0 lret=0 v

	debug-print "${FUNCNAME}: initial build_dir = ${bdir}"

	for v in "${MULTIBUILD_VARIANTS[@]}"; do
		local MULTIBUILD_VARIANT=${v}
		local MULTIBUILD_ID=${prev_id}${v}
		local BUILD_DIR=${bdir%%/}-${v}

		_multibuild_run() {
			# find the first non-private command
			local i=1
			while [[ ${!i} == _* ]]; do
				(( i += 1 ))
			done

			[[ ${i} -le ${#} ]] && einfo "${v}: running ${@:${i}}"
			"${@}"
		}

		_multibuild_run "${@}" \
			> >(exec tee -a "${T}/build-${MULTIBUILD_ID}.log") 2>&1
		lret=${?}
	done
	[[ ${ret} -eq 0 && ${lret} -ne 0 ]] && ret=${lret}

	return ${ret}
}

# @FUNCTION: multibuild_parallel_foreach_variant
# @USAGE: [<argv>...]
# @DESCRIPTION:
# Run the passed command repeatedly for each of the enabled package
# variants alike multibuild_foreach_variant. Multiple invocations of the command
# will be performed in parallel, up to MULTIBUILD_JOBS tasks.
#
# The function returns 0 if all commands return 0, or the first non-zero
# exit status otherwise. However, it performs all the invocations
# nevertheless. It is preferred to call 'die' inside of the passed
# function.
multibuild_parallel_foreach_variant() {
	debug-print-function ${FUNCNAME} "${@}"

	local ret lret

	_multibuild_parallel() {
		(
			multijob_child_init
			"${@}"
		) &
		multijob_post_fork
	}

	local opts
	if [[ ${MULTIBUILD_JOBS} ]]; then
		opts=-j${MULTIBUILD_JOBS}
	else
		opts=${MAKEOPTS}
	fi

	multijob_init "${opts}"
	multibuild_foreach_variant _multibuild_parallel "${@}"
	ret=${?}
	multijob_finish
	lret=${?}

	[[ ${ret} -eq 0 ]] && ret=${lret}
	return ${ret}
}

# @FUNCTION: multibuild_for_best_variant
# @USAGE: [<argv>...]
# @DESCRIPTION:
# Run the passed command once, for the best of the enabled package
# variants.
#
# The run will have a proper, variant-specificBUILD_DIR set, and output
# teed to a separate log in ${T}.
#
# The function returns command exit status.
multibuild_for_best_variant() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${MULTIBUILD_VARIANTS} ]] \
		|| die "MULTIBUILD_VARIANTS need to be set"

	# bash-4.1 can't handle negative subscripts
	local MULTIBUILD_VARIANTS=(
		"${MULTIBUILD_VARIANTS[$(( ${#MULTIBUILD_VARIANTS[@]} - 1 ))]}"
	)
	multibuild_foreach_variant "${@}"
}

# @FUNCTION: multibuild_copy_sources
# @DESCRIPTION:
# Create per-variant copies of source tree. The source tree is assumed
# to be in ${BUILD_DIR}, or ${S} if the former is unset. The copies will
# be placed in directories matching BUILD_DIRs used by
# multibuild_foreach().
multibuild_copy_sources() {
	debug-print-function ${FUNCNAME} "${@}"

	local _MULTIBUILD_INITIAL_BUILD_DIR=${BUILD_DIR:-${S}}

	einfo "Will copy sources from ${_MULTIBUILD_INITIAL_BUILD_DIR}"

	_multibuild_create_source_copy() {
		einfo "${MULTIBUILD_VARIANT}: copying to ${BUILD_DIR}"
		cp -pr "${_MULTIBUILD_INITIAL_BUILD_DIR}" "${BUILD_DIR}" || die
	}

	multibuild_foreach_variant _multibuild_create_source_copy
}

# @FUNCTION: run_in_build_dir
# @USAGE: <argv>...
# @DESCRIPTION:
# Run the given command in the directory pointed by BUILD_DIR.
run_in_build_dir() {
	debug-print-function ${FUNCNAME} "${@}"
	local ret

	[[ ${#} -ne 0 ]] || die "${FUNCNAME}: no command specified."
	[[ ${BUILD_DIR} ]] || die "${FUNCNAME}: BUILD_DIR not set."

	pushd "${BUILD_DIR}" >/dev/null || die
	"${@}"
	ret=${?}
	popd >/dev/null || die

	return ${ret}
}

# @FUNCTION: multibuild_merge_root
# @USAGE: <src-root> <dest-root>
# @DESCRIPTION:
# Merge the directory tree (fake root) from <src-root> to <dest-root>
# (the real root). Both directories have to be real, absolute paths
# (i.e. including ${D}). Source root will be removed.
#
# This functions uses locking to support merging during parallel
# installs.
multibuild_merge_root() {
	local src=${1}
	local dest=${2}

	local lockfile=${T}/.multibuild_merge_lock
	local lockfile_l=${lockfile}.${BASHPID}
	local ret

	# Lock the install tree for merge. The touch+ln method ensures race
	# condition-free locking with maximum portability.
	touch "${lockfile_l}" || die
	until ln "${lockfile_l}" "${lockfile}" &>/dev/null; do
		sleep 1
	done
	rm "${lockfile_l}" || die

	if use userland_BSD; then
		# 'cp -a -n' is broken:
		# http://www.freebsd.org/cgi/query-pr.cgi?pr=174489
		# using tar instead which is universal but terribly slow.

		tar -C "${src}" -f - -c . \
			| tar -x -f - -C "${dest}"
		[[ ${PIPESTATUS[*]} == '0 0' ]]
		ret=${?}
	elif use userland_GNU; then
		# cp works with '-a -n'.

		cp -a -l -n "${src}"/. "${dest}"/
		ret=${?}
	else
		die "Unsupported userland (${USERLAND}), please report."
	fi

	# Remove the lock.
	rm "${lockfile}" || die

	if [[ ${ret} -ne 0 ]]; then
		die "${MULTIBUILD_VARIANT:-(unknown)}: merging image failed."
	fi

	rm -rf "${src}"
}

_MULTIBUILD=1
fi
