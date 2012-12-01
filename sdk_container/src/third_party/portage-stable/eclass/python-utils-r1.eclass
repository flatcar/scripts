# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/python-utils-r1.eclass,v 1.5 2012/11/30 11:43:14 mgorny Exp $

# @ECLASS: python-utils-r1
# @MAINTAINER:
# Michał Górny <mgorny@gentoo.org>
# Python herd <python@gentoo.org>
# @AUTHOR:
# Author: Michał Górny <mgorny@gentoo.org>
# Based on work of: Krzysztof Pawlik <nelchael@gentoo.org>
# @BLURB: Utility functions for packages with Python parts.
# @DESCRIPTION:
# An utility eclass providing functions to query Python implementations,
# install Python modules and scripts.
#
# This eclass does not set any metadata variables nor export any phase
# functions. It can be inherited safely.
#
# For more information, please see the python-r1 Developer's Guide:
# http://www.gentoo.org/proj/en/Python/python-r1/dev-guide.xml

case "${EAPI:-0}" in
	0|1|2|3|4|5)
		# EAPI=4 makes die behavior clear
		;;
	*)
		die "Unsupported EAPI=${EAPI} (unknown) for ${ECLASS}"
		;;
esac

if [[ ${_PYTHON_ECLASS_INHERITED} ]]; then
	die 'python-r1 suite eclasses can not be used with python.eclass.'
fi

if [[ ! ${_PYTHON_UTILS_R1} ]]; then

inherit multilib

# @ECLASS-VARIABLE: _PYTHON_ALL_IMPLS
# @INTERNAL
# @DESCRIPTION:
# All supported Python implementations, most preferred last.
_PYTHON_ALL_IMPLS=(
	jython2_5
	pypy1_8 pypy1_9
	python3_1 python3_2 python3_3
	python2_5 python2_6 python2_7
)

# @ECLASS-VARIABLE: PYTHON
# @DESCRIPTION:
# The absolute path to the current Python interpreter.
#
# Set and exported only in commands run by python_foreach_impl().
#
# Example value:
# @CODE
# /usr/bin/python2.6
# @CODE

# @ECLASS-VARIABLE: EPYTHON
# @DESCRIPTION:
# The executable name of the current Python interpreter.
#
# This variable is used consistently with python.eclass.
#
# Set and exported only in commands run by python_foreach_impl().
#
# Example value:
# @CODE
# python2.6
# @CODE

# @ECLASS-VARIABLE: PYTHON_SITEDIR
# @DESCRIPTION:
# The path to Python site-packages directory.
#
# Set and exported on request using python_export().
#
# Example value:
# @CODE
# /usr/lib64/python2.6/site-packages
# @CODE

# @FUNCTION: python_export
# @USAGE: [<impl>] <variables>...
# @DESCRIPTION:
# Set and export the Python implementation-relevant variables passed
# as parameters.
#
# The optional first parameter may specify the requested Python
# implementation (either as PYTHON_TARGETS value, e.g. python2_7,
# or an EPYTHON one, e.g. python2.7). If no implementation passed,
# the current one will be obtained from ${EPYTHON}.
#
# The variables which can be exported are: PYTHON, EPYTHON,
# PYTHON_SITEDIR. They are described more completely in the eclass
# variable documentation.
python_export() {
	debug-print-function ${FUNCNAME} "${@}"

	local impl var

	case "${1}" in
		python*|jython*)
			impl=${1/_/.}
			shift
			;;
		pypy-c*)
			impl=${1}
			shift
			;;
		pypy*)
			local v=${1#pypy}
			impl=pypy-c${v/_/.}
			shift
			;;
		*)
			impl=${EPYTHON}
			[[ ${impl} ]] || die "python_export: no impl nor EPYTHON"
			;;
	esac
	debug-print "${FUNCNAME}: implementation: ${impl}"

	for var; do
		case "${var}" in
			EPYTHON)
				export EPYTHON=${impl}
				debug-print "${FUNCNAME}: EPYTHON = ${EPYTHON}"
				;;
			PYTHON)
				export PYTHON=${EPREFIX}/usr/bin/${impl}
				debug-print "${FUNCNAME}: PYTHON = ${PYTHON}"
				;;
			PYTHON_SITEDIR)
				local dir
				case "${impl}" in
					python*)
						dir=/usr/$(get_libdir)/${impl}
						;;
					jython*)
						dir=/usr/share/${impl}/Lib
						;;
					pypy*)
						dir=/usr/$(get_libdir)/${impl/-c/}
						;;
				esac

				export PYTHON_SITEDIR=${EPREFIX}${dir}/site-packages
				debug-print "${FUNCNAME}: PYTHON_SITEDIR = ${PYTHON_SITEDIR}"
				;;
			*)
				die "python_export: unknown variable ${var}"
		esac
	done
}

# @FUNCTION: python_get_PYTHON
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the path to the Python interpreter for the given
# implementation. If no implementation is provided, ${EPYTHON} will
# be used.
#
# If you just need to have PYTHON set (and exported), then it is better
# to use python_export() directly instead.
python_get_PYTHON() {
	debug-print-function ${FUNCNAME} "${@}"

	python_export "${@}" PYTHON
	echo "${PYTHON}"
}

# @FUNCTION: python_get_EPYTHON
# @USAGE: <impl>
# @DESCRIPTION:
# Obtain and print the EPYTHON value for the given implementation.
#
# If you just need to have EPYTHON set (and exported), then it is better
# to use python_export() directly instead.
python_get_EPYTHON() {
	debug-print-function ${FUNCNAME} "${@}"

	python_export "${@}" EPYTHON
	echo "${EPYTHON}"
}

# @FUNCTION: python_get_sitedir
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the 'site-packages' path for the given
# implementation. If no implementation is provided, ${EPYTHON} will
# be used.
#
# If you just need to have PYTHON_SITEDIR set (and exported), then it is
# better to use python_export() directly instead.
python_get_sitedir() {
	debug-print-function ${FUNCNAME} "${@}"

	python_export "${@}" PYTHON_SITEDIR
	echo "${PYTHON_SITEDIR}"
}

# @FUNCTION: _python_rewrite_shebang
# @INTERNAL
# @USAGE: [<EPYTHON>] <path>...
# @DESCRIPTION:
# Replaces 'python' executable in the shebang with the executable name
# of the specified interpreter. If no EPYTHON value (implementation) is
# used, the current ${EPYTHON} will be used.
#
# All specified files must start with a 'python' shebang. A file not
# having a matching shebang will be refused. The exact shebang style
# will be preserved in order not to break anything.
#
# Example conversions:
# @CODE
# From: #!/usr/bin/python -R
# To: #!/usr/bin/python2.7 -R
#
# From: #!/usr/bin/env FOO=bar python
# To: #!/usr/bin/env FOO=bar python2.7
# @CODE
_python_rewrite_shebang() {
	debug-print-function ${FUNCNAME} "${@}"

	local impl
	case "${1}" in
		python*|jython*|pypy-c*)
			impl=${1}
			shift
			;;
		*)
			impl=${EPYTHON}
			[[ ${impl} ]] || die "${FUNCNAME}: no impl nor EPYTHON"
			;;
	esac
	debug-print "${FUNCNAME}: implementation: ${impl}"

	local f
	for f; do
		local shebang=$(head -n 1 "${f}")
		debug-print "${FUNCNAME}: path = ${f}"
		debug-print "${FUNCNAME}: shebang = ${shebang}"

		if [[ "${shebang} " != *'python '* ]]; then
			eerror "A file does not seem to have a supported shebang:"
			eerror "  file: ${f}"
			eerror "  shebang: ${shebang}"
			die "${FUNCNAME}: ${f} does not seem to have a valid shebang"
		fi

		sed -i -e "1s:python:${impl}:" "${f}" || die
	done
}

# @FUNCTION: _python_ln_rel
# @INTERNAL
# @USAGE: <from> <to>
# @DESCRIPTION:
# Create a relative symlink.
_python_ln_rel() {
	debug-print-function ${FUNCNAME} "${@}"

	local from=${1}
	local to=${2}

	local frpath=${from%/*}/
	local topath=${to%/*}/
	local rel_path=

	# remove double slashes
	frpath=${frpath/\/\///}
	topath=${topath/\/\///}

	while [[ ${topath} ]]; do
		local frseg=${frpath%%/*}
		local toseg=${topath%%/*}

		if [[ ${frseg} != ${toseg} ]]; then
			rel_path=../${rel_path}${frseg:+${frseg}/}
		fi

		frpath=${frpath#${frseg}/}
		topath=${topath#${toseg}/}
	done
	rel_path+=${frpath}${1##*/}

	debug-print "${FUNCNAME}: ${from} -> ${to}"
	debug-print "${FUNCNAME}: rel_path = ${rel_path}"

	ln -fs "${rel_path}" "${to}"
}

# @FUNCTION: python_optimize
# @USAGE: [<directory>...]
# @DESCRIPTION:
# Compile and optimize Python modules in specified directories (absolute
# paths). If no directories are provided, the default system paths
# are used (prepended with ${D}).
python_optimize() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${EPYTHON} ]] || die 'No Python implementation set (EPYTHON is null).'

	local PYTHON=${PYTHON}
	[[ ${PYTHON} ]] || python_export PYTHON

	# Note: python2.6 can't handle passing files to compileall...

	# default to sys.path
	if [[ ${#} -eq 0 ]]; then
		local f
		while IFS= read -r -d '' f; do
			# 1) accept only absolute paths
			#    (i.e. skip '', '.' or anything like that)
			# 2) skip paths which do not exist
			#    (python2.6 complains about them verbosely)

			if [[ ${f} == /* && -d ${D}${f} ]]; then
				set -- "${D}${f}" "${@}"
			fi
		done < <("${PYTHON}" -c 'import sys; print("\0".join(sys.path))')
	fi

	local d
	for d; do
		# make sure to get a nice path without //
		local instpath=${d#${D}}
		instpath=/${instpath##/}

		case "${EPYTHON}" in
			python*)
				"${PYTHON}" -m compileall -q -f -d "${instpath}" "${d}"
				"${PYTHON}" -OO -m compileall -q -f -d "${instpath}" "${d}"
				;;
			*)
				"${PYTHON}" -m compileall -q -f -d "${instpath}" "${@}"
				;;
		esac
	done
}

# @ECLASS-VARIABLE: python_scriptroot
# @DEFAULT_UNSET
# @DESCRIPTION:
# The current script destination for python_doscript(). The path
# is relative to the installation root (${ED}).
#
# When unset, ${DESTTREE}/bin (/usr/bin by default) will be used.
#
# Can be set indirectly through the python_scriptinto() function.
#
# Example:
# @CODE
# src_install() {
#   local python_scriptroot=${GAMES_BINDIR}
#   python_foreach_impl python_doscript foo
# }
# @CODE

# @FUNCTION: python_scriptinto
# @USAGE: <new-path>
# @DESCRIPTION:
# Set the current scriptroot. The new value will be stored
# in the 'python_scriptroot' environment variable. The new value need
# be relative to the installation root (${ED}).
#
# Alternatively, you can set the variable directly.
python_scriptinto() {
	debug-print-function ${FUNCNAME} "${@}"

	python_scriptroot=${1}
}

# @FUNCTION: python_doscript
# @USAGE: <files>...
# @DESCRIPTION:
# Install the given scripts into current python_scriptroot,
# for the current Python implementation (${EPYTHON}).
#
# All specified files must start with a 'python' shebang. The shebang
# will be converted, the file will be renamed to be EPYTHON-suffixed
# and a wrapper will be installed in place of the original name.
#
# Example:
# @CODE
# src_install() {
#   python_foreach_impl python_doscript ${PN}
# }
# @CODE
python_doscript() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${EPYTHON} ]] || die 'No Python implementation set (EPYTHON is null).'

	local d=${python_scriptroot:-${DESTTREE}/bin}
	local INSDESTTREE INSOPTIONS

	insinto "${d}"
	insopts -m755

	local f
	for f; do
		local oldfn=${f##*/}
		local newfn=${oldfn}-${EPYTHON}

		debug-print "${FUNCNAME}: ${oldfn} -> ${newfn}"
		newins "${f}" "${newfn}" || die
		_python_rewrite_shebang "${D}/${d}/${newfn}"

		# install the wrapper
		_python_ln_rel "${ED}"/usr/bin/python-exec "${D}/${d}/${oldfn}" || die
	done
}

# @ECLASS-VARIABLE: python_moduleroot
# @DEFAULT_UNSET
# @DESCRIPTION:
# The current module root for python_domodule(). The path can be either
# an absolute system path (it must start with a slash, and ${D} will be
# prepended to it) or relative to the implementation's site-packages directory
# (then it must start with a non-slash character).
#
# When unset, the modules will be installed in the site-packages root.
#
# Can be set indirectly through the python_moduleinto() function.
#
# Example:
# @CODE
# src_install() {
#   local python_moduleroot=bar
#   # installs ${PYTHON_SITEDIR}/bar/baz.py
#   python_foreach_impl python_domodule baz.py
# }
# @CODE

# @FUNCTION: python_moduleinto
# @USAGE: <new-path>
# @DESCRIPTION:
# Set the current module root. The new value will be stored
# in the 'python_moduleroot' environment variable. The new value need
# be relative to the site-packages root.
#
# Alternatively, you can set the variable directly.
python_moduleinto() {
	debug-print-function ${FUNCNAME} "${@}"

	python_moduleroot=${1}
}

# @FUNCTION: python_domodule
# @USAGE: <files>...
# @DESCRIPTION:
# Install the given modules (or packages) into the current
# python_moduleroot. The list can mention both modules (files)
# and packages (directories). All listed files will be installed
# for all enabled implementations, and compiled afterwards.
#
# Example:
# @CODE
# src_install() {
#   # (${PN} being a directory)
#   python_foreach_impl python_domodule ${PN}
# }
# @CODE
python_domodule() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${EPYTHON} ]] || die 'No Python implementation set (EPYTHON is null).'

	local d
	if [[ ${python_moduleroot} == /* ]]; then
		# absolute path
		d=${python_moduleroot}
	else
		# relative to site-packages
		local PYTHON_SITEDIR=${PYTHON_SITEDIR}
		[[ ${PYTHON_SITEDIR} ]] || python_export PYTHON_SITEDIR

		d=${PYTHON_SITEDIR}/${python_moduleroot}
	fi

	local INSDESTTREE

	insinto "${d}"
	doins -r "${@}" || die

	python_optimize "${D}/${d}"
}

_PYTHON_UTILS_R1=1
fi
