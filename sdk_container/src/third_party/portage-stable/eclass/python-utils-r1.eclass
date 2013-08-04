# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/python-utils-r1.eclass,v 1.30 2013/07/27 11:17:44 mgorny Exp $

# @ECLASS: python-utils-r1
# @MAINTAINER:
# Python team <python@gentoo.org>
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

inherit multilib toolchain-funcs

# @ECLASS-VARIABLE: _PYTHON_ALL_IMPLS
# @INTERNAL
# @DESCRIPTION:
# All supported Python implementations, most preferred last.
_PYTHON_ALL_IMPLS=(
	jython2_5 jython2_7
	pypy1_9 pypy2_0
	python3_1 python3_2 python3_3
	python2_5 python2_6 python2_7
)

# @FUNCTION: _python_impl_supported
# @USAGE: <impl>
# @INTERNAL
# @DESCRIPTION:
# Check whether the implementation <impl> (PYTHON_COMPAT-form)
# is still supported.
#
# Returns 0 if the implementation is valid and supported. If it is
# unsupported, returns 1 -- and the caller should ignore the entry.
# If it is invalid, dies with an appopriate error messages.
_python_impl_supported() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${#} -eq 1 ]] || die "${FUNCNAME}: takes exactly 1 argument (impl)."

	local impl=${1}

	# keep in sync with _PYTHON_ALL_IMPLS!
	# (not using that list because inline patterns shall be faster)
	case "${impl}" in
		python2_[567]|python3_[123]|pypy1_9|pypy2_0|jython2_[57])
			return 0
			;;
		pypy1_8)
			return 1
			;;
		*)
			die "Invalid implementation in PYTHON_COMPAT: ${impl}"
	esac
}

# @ECLASS-VARIABLE: PYTHON
# @DEFAULT_UNSET
# @DESCRIPTION:
# The absolute path to the current Python interpreter.
#
# This variable is set automatically in the following contexts:
#
# python-r1: Set in functions called by python_foreach_impl() or after
# calling python_export_best().
#
# python-single-r1: Set after calling python-single-r1_pkg_setup().
#
# distutils-r1: Set within any of the python sub-phase functions.
#
# Example value:
# @CODE
# /usr/bin/python2.6
# @CODE

# @ECLASS-VARIABLE: EPYTHON
# @DEFAULT_UNSET
# @DESCRIPTION:
# The executable name of the current Python interpreter.
#
# This variable is set automatically in the following contexts:
#
# python-r1: Set in functions called by python_foreach_impl() or after
# calling python_export_best().
#
# python-single-r1: Set after calling python-single-r1_pkg_setup().
#
# distutils-r1: Set within any of the python sub-phase functions.
#
# Example value:
# @CODE
# python2.6
# @CODE

# @ECLASS-VARIABLE: PYTHON_SITEDIR
# @DEFAULT_UNSET
# @DESCRIPTION:
# The path to Python site-packages directory.
#
# Set and exported on request using python_export().
#
# Example value:
# @CODE
# /usr/lib64/python2.6/site-packages
# @CODE

# @ECLASS-VARIABLE: PYTHON_INCLUDEDIR
# @DEFAULT_UNSET
# @DESCRIPTION:
# The path to Python include directory.
#
# Set and exported on request using python_export().
#
# Example value:
# @CODE
# /usr/include/python2.6
# @CODE

# @ECLASS-VARIABLE: PYTHON_LIBPATH
# @DEFAULT_UNSET
# @DESCRIPTION:
# The path to Python library.
#
# Set and exported on request using python_export().
# Valid only for CPython.
#
# Example value:
# @CODE
# /usr/lib64/libpython2.6.so
# @CODE

# @ECLASS-VARIABLE: PYTHON_CFLAGS
# @DEFAULT_UNSET
# @DESCRIPTION:
# Proper C compiler flags for building against Python. Obtained from
# pkg-config or python-config.
#
# Set and exported on request using python_export().
# Valid only for CPython. Requires a proper build-time dependency
# on the Python implementation and on pkg-config.
#
# Example value:
# @CODE
# -I/usr/include/python2.7
# @CODE

# @ECLASS-VARIABLE: PYTHON_LIBS
# @DEFAULT_UNSET
# @DESCRIPTION:
# Proper C compiler flags for linking against Python. Obtained from
# pkg-config or python-config.
#
# Set and exported on request using python_export().
# Valid only for CPython. Requires a proper build-time dependency
# on the Python implementation and on pkg-config.
#
# Example value:
# @CODE
# -lpython2.7
# @CODE

# @ECLASS-VARIABLE: PYTHON_PKG_DEP
# @DEFAULT_UNSET
# @DESCRIPTION:
# The complete dependency on a particular Python package as a string.
#
# Set and exported on request using python_export().
#
# Example value:
# @CODE
# dev-lang/python:2.7[xml]
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
			PYTHON_INCLUDEDIR)
				local dir
				case "${impl}" in
					python*)
						dir=/usr/include/${impl}
						;;
					jython*)
						dir=/usr/share/${impl}/Include
						;;
					pypy*)
						dir=/usr/$(get_libdir)/${impl/-c/}/include
						;;
				esac

				export PYTHON_INCLUDEDIR=${EPREFIX}${dir}
				debug-print "${FUNCNAME}: PYTHON_INCLUDEDIR = ${PYTHON_INCLUDEDIR}"
				;;
			PYTHON_LIBPATH)
				local libname
				case "${impl}" in
					python*)
						libname=lib${impl}
						;;
					*)
						die "${impl} lacks a dynamic library"
						;;
				esac

				local path=${EPREFIX}/usr/$(get_libdir)

				export PYTHON_LIBPATH=${path}/${libname}$(get_libname)
				debug-print "${FUNCNAME}: PYTHON_LIBPATH = ${PYTHON_LIBPATH}"
				;;
			PYTHON_CFLAGS)
				local val

				case "${impl}" in
					python2.5|python2.6)
						# old versions support python-config only
						val=$("${impl}-config" --includes)
						;;
					python*)
						# python-2.7, python-3.2, etc.
						val=$($(tc-getPKG_CONFIG) --cflags ${impl/n/n-})
						;;
					*)
						die "${impl}: obtaining ${var} not supported"
						;;
				esac

				export PYTHON_CFLAGS=${val}
				debug-print "${FUNCNAME}: PYTHON_CFLAGS = ${PYTHON_CFLAGS}"
				;;
			PYTHON_LIBS)
				local val

				case "${impl}" in
					python2.5|python2.6)
						# old versions support python-config only
						val=$("${impl}-config" --libs)
						;;
					python*)
						# python-2.7, python-3.2, etc.
						val=$($(tc-getPKG_CONFIG) --libs ${impl/n/n-})
						;;
					*)
						die "${impl}: obtaining ${var} not supported"
						;;
				esac

				export PYTHON_LIBS=${val}
				debug-print "${FUNCNAME}: PYTHON_LIBS = ${PYTHON_LIBS}"
				;;
			PYTHON_PKG_DEP)
				local d
				case ${impl} in
					python*)
						PYTHON_PKG_DEP='dev-lang/python';;
					jython*)
						PYTHON_PKG_DEP='dev-java/jython';;
					pypy*)
						PYTHON_PKG_DEP='virtual/pypy';;
					*)
						die "Invalid implementation: ${impl}"
				esac

				# slot
				PYTHON_PKG_DEP+=:${impl##*[a-z-]}

				# use-dep
				if [[ ${PYTHON_REQ_USE} ]]; then
					PYTHON_PKG_DEP+=[${PYTHON_REQ_USE}]
				fi

				export PYTHON_PKG_DEP
				debug-print "${FUNCNAME}: PYTHON_PKG_DEP = ${PYTHON_PKG_DEP}"
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

# @FUNCTION: python_get_includedir
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the include path for the given implementation. If no
# implementation is provided, ${EPYTHON} will be used.
#
# If you just need to have PYTHON_INCLUDEDIR set (and exported), then it
# is better to use python_export() directly instead.
python_get_includedir() {
	debug-print-function ${FUNCNAME} "${@}"

	python_export "${@}" PYTHON_INCLUDEDIR
	echo "${PYTHON_INCLUDEDIR}"
}

# @FUNCTION: python_get_library_path
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the Python library path for the given implementation.
# If no implementation is provided, ${EPYTHON} will be used.
#
# Please note that this function can be used with CPython only. Use
# in another implementation will result in a fatal failure.
python_get_library_path() {
	debug-print-function ${FUNCNAME} "${@}"

	python_export "${@}" PYTHON_LIBPATH
	echo "${PYTHON_LIBPATH}"
}

# @FUNCTION: python_get_CFLAGS
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the compiler flags for building against Python,
# for the given implementation. If no implementation is provided,
# ${EPYTHON} will be used.
#
# Please note that this function can be used with CPython only.
# It requires Python and pkg-config installed, and therefore proper
# build-time dependencies need be added to the ebuild.
python_get_CFLAGS() {
	debug-print-function ${FUNCNAME} "${@}"

	python_export "${@}" PYTHON_CFLAGS
	echo "${PYTHON_CFLAGS}"
}

# @FUNCTION: python_get_LIBS
# @USAGE: [<impl>]
# @DESCRIPTION:
# Obtain and print the compiler flags for linking against Python,
# for the given implementation. If no implementation is provided,
# ${EPYTHON} will be used.
#
# Please note that this function can be used with CPython only.
# It requires Python and pkg-config installed, and therefore proper
# build-time dependencies need be added to the ebuild.
python_get_LIBS() {
	debug-print-function ${FUNCNAME} "${@}"

	python_export "${@}" PYTHON_LIBS
	echo "${PYTHON_LIBS}"
}

# @FUNCTION: _python_rewrite_shebang
# @USAGE: [<EPYTHON>] <path>...
# @INTERNAL
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
		local from shebang
		read -r shebang < "${f}"
		shebang=${shebang%$'\r'}
		debug-print "${FUNCNAME}: path = ${f}"
		debug-print "${FUNCNAME}: shebang = ${shebang}"

		if [[ "${shebang} " == *'python '* ]]; then
			from=python
		elif [[ "${shebang} " == *'python2 '* ]]; then
			from=python2
		elif [[ "${shebang} " == *'python3 '* ]]; then
			from=python3
		else
			eerror "A file does not seem to have a supported shebang:"
			eerror "  file: ${f}"
			eerror "  shebang: ${shebang}"
			die "${FUNCNAME}: ${f} does not seem to have a valid shebang"
		fi

		if [[ ${from} == python2 && ${impl} == python3*
				|| ${from} == python3 && ${impl} != python3* ]]; then
			eerror "A file does have shebang not supporting requested impl:"
			eerror "  file: ${f}"
			eerror "  shebang: ${shebang}"
			eerror "  impl: ${impl}"
			die "${FUNCNAME}: ${f} does have shebang not supporting ${EPYTHON}"
		fi

		sed -i -e "1s:${from}:${impl}:" "${f}" || die
	done
}

# @FUNCTION: _python_ln_rel
# @USAGE: <from> <to>
# @INTERNAL
# @DESCRIPTION:
# Create a relative symlink.
_python_ln_rel() {
	debug-print-function ${FUNCNAME} "${@}"

	local from=${1}
	local to=${2}

	local frpath=${from%/*}/
	local topath=${to%/*}/
	local rel_path=

	while [[ ${topath} ]]; do
		local frseg= toseg=

		while [[ ! ${frseg} && ${frpath} ]]; do
			frseg=${frpath%%/*}
			frpath=${frpath#${frseg}/}
		done

		while [[ ! ${toseg} && ${topath} ]]; do
			toseg=${topath%%/*}
			topath=${topath#${toseg}/}
		done

		if [[ ${frseg} != ${toseg} ]]; then
			rel_path=../${rel_path}${frseg:+${frseg}/}
		fi
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

	if [[ ${EBUILD_PHASE} == pre* || ${EBUILD_PHASE} == post* ]]; then
		eerror "The new Python eclasses expect the compiled Python files to"
		eerror "be controlled by the Package Manager. For this reason,"
		eerror "the python_optimize function can be used only during src_* phases"
		eerror "(src_install most commonly) and not during pkg_* phases."
		echo
		die "python_optimize is not to be used in pre/post* phases"
	fi

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

		debug-print "${FUNCNAME}: using sys.path: ${*/%/;}"
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
				"${PYTHON}" -m compileall -q -f -d "${instpath}" "${d}"
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

	local f
	for f; do
		python_newscript "${f}" "${f##*/}"
	done
}

# @FUNCTION: python_newscript
# @USAGE: <path> <new-name>
# @DESCRIPTION:
# Install the given script into current python_scriptroot
# for the current Python implementation (${EPYTHON}), and name it
# <new-name>.
#
# The file must start with a 'python' shebang. The shebang will be
# converted, the file will be renamed to be EPYTHON-suffixed
# and a wrapper will be installed in place of the <new-name>.
#
# Example:
# @CODE
# src_install() {
#   python_foreach_impl python_newscript foo.py foo
# }
# @CODE
python_newscript() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${EPYTHON} ]] || die 'No Python implementation set (EPYTHON is null).'
	[[ ${#} -eq 2 ]] || die "Usage: ${FUNCNAME} <path> <new-name>"

	local d=${python_scriptroot:-${DESTTREE}/bin}
	local INSDESTTREE INSOPTIONS

	insinto "${d}"
	insopts -m755

	local f=${1}
	local barefn=${2}

	local newfn=${barefn}-${EPYTHON}

	debug-print "${FUNCNAME}: ${f} -> ${d}/${newfn}"
	newins "${f}" "${newfn}" || die
	_python_rewrite_shebang "${ED}/${d}/${newfn}"

	# install the wrapper
	_python_ln_rel "${ED}"/usr/bin/python-exec "${ED}/${d}/${barefn}" || die
}

# @ECLASS-VARIABLE: python_moduleroot
# @DEFAULT_UNSET
# @DESCRIPTION:
# The current module root for python_domodule(). The path can be either
# an absolute system path (it must start with a slash, and ${ED} will be
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

		d=${PYTHON_SITEDIR#${EPREFIX}}/${python_moduleroot}
	fi

	local INSDESTTREE

	insinto "${d}"
	doins -r "${@}" || die

	python_optimize "${ED}/${d}"
}

# @FUNCTION: python_doheader
# @USAGE: <files>...
# @DESCRIPTION:
# Install the given headers into the implementation-specific include
# directory. This function is unconditionally recursive, i.e. you can
# pass directories instead of files.
#
# Example:
# @CODE
# src_install() {
#   python_foreach_impl python_doheader foo.h bar.h
# }
# @CODE
python_doheader() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${EPYTHON} ]] || die 'No Python implementation set (EPYTHON is null).'

	local d PYTHON_INCLUDEDIR=${PYTHON_INCLUDEDIR}
	[[ ${PYTHON_INCLUDEDIR} ]] || python_export PYTHON_INCLUDEDIR

	d=${PYTHON_INCLUDEDIR#${EPREFIX}}

	local INSDESTTREE

	insinto "${d}"
	doins -r "${@}" || die
}

# @FUNCTION: python_wrapper_setup
# @USAGE: [<path> [<impl>]]
# @DESCRIPTION:
# Create proper 'python' executable and pkg-config wrappers
# (if available) in the directory named by <path>. Set up PATH
# and PKG_CONFIG_PATH appropriately. <path> defaults to ${T}/${EPYTHON}.
#
# The wrappers will be created for implementation named by <impl>,
# or for one named by ${EPYTHON} if no <impl> passed.
#
# If the named directory contains a python symlink already, it will
# be assumed to contain proper wrappers already and only environment
# setup will be done. If wrapper update is requested, the directory
# shall be removed first.
python_wrapper_setup() {
	debug-print-function ${FUNCNAME} "${@}"

	local workdir=${1:-${T}/${EPYTHON}}
	local impl=${2:-${EPYTHON}}

	[[ ${workdir} ]] || die "${FUNCNAME}: no workdir specified."
	[[ ${impl} ]] || die "${FUNCNAME}: no impl nor EPYTHON specified."

	if [[ ! -x ${workdir}/bin/python ]]; then
		mkdir -p "${workdir}"/{bin,pkgconfig} || die

		# Clean up, in case we were supposed to do a cheap update.
		rm -f "${workdir}"/bin/python{,2,3,-config}
		rm -f "${workdir}"/bin/2to3
		rm -f "${workdir}"/pkgconfig/python{,2,3}.pc

		local EPYTHON PYTHON
		python_export "${impl}" EPYTHON PYTHON

		local pyver
		if [[ ${EPYTHON} == python3* ]]; then
			pyver=3
		else # includes pypy & jython
			pyver=2
		fi

		# Python interpreter
		ln -s "${PYTHON}" "${workdir}"/bin/python || die
		ln -s python "${workdir}"/bin/python${pyver} || die

		local nonsupp=()

		# CPython-specific
		if [[ ${EPYTHON} == python* ]]; then
			ln -s "${PYTHON}-config" "${workdir}"/bin/python-config || die

			# Python 2.6+.
			if [[ ${EPYTHON} != python2.5 ]]; then
				ln -s "${PYTHON/python/2to3-}" "${workdir}"/bin/2to3 || die
			else
				nonsupp+=( 2to3 )
			fi

			# Python 2.7+.
			if [[ ${EPYTHON} != python2.[56] ]]; then
				ln -s "${EPREFIX}"/usr/$(get_libdir)/pkgconfig/${EPYTHON/n/n-}.pc \
					"${workdir}"/pkgconfig/python.pc || die
			else
				# XXX?
				ln -s /dev/null "${workdir}"/pkgconfig/python.pc || die
			fi
			ln -s python.pc "${workdir}"/pkgconfig/python${pyver}.pc || die
		else
			nonsupp+=( 2to3 python-config )
		fi

		local x
		for x in "${nonsupp[@]}"; do
			cat >"${workdir}"/bin/${x} <<__EOF__
#!/bin/sh
echo "${x} is not supported by ${EPYTHON}" >&2
exit 1
__EOF__
			chmod +x "${workdir}"/bin/${x} || die
		done

		# Now, set the environment.
		# But note that ${workdir} may be shared with something else,
		# and thus already on top of PATH.
		if [[ ${PATH##:*} != ${workdir}/bin ]]; then
			PATH=${workdir}/bin${PATH:+:${PATH}}
		fi
		if [[ ${PKG_CONFIG_PATH##:*} != ${workdir}/pkgconfig ]]; then
			PKG_CONFIG_PATH=${workdir}/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}
		fi
		export PATH PKG_CONFIG_PATH
	fi
}

_PYTHON_UTILS_R1=1
fi
