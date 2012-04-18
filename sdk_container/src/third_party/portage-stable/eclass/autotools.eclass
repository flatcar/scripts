# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/autotools.eclass,v 1.130 2012/03/22 19:16:22 vapier Exp $

# @ECLASS: autotools.eclass
# @MAINTAINER:
# base-system@gentoo.org
# @BLURB: Regenerates auto* build scripts
# @DESCRIPTION:
# This eclass is for safely handling autotooled software packages that need to
# regenerate their build scripts.  All functions will abort in case of errors.

# Note: We require GNU m4, as does autoconf.  So feel free to use any features
# from the GNU version of m4 without worrying about other variants (i.e. BSD).

if [[ ${___ECLASS_ONCE_AUTOTOOLS} != "recur -_+^+_- spank" ]] ; then
___ECLASS_ONCE_AUTOTOOLS="recur -_+^+_- spank"

inherit eutils libtool

# @ECLASS-VARIABLE: WANT_AUTOCONF
# @DESCRIPTION:
# The major version of autoconf your package needs
: ${WANT_AUTOCONF:=latest}

# @ECLASS-VARIABLE: WANT_AUTOMAKE
# @DESCRIPTION:
# The major version of automake your package needs
: ${WANT_AUTOMAKE:=latest}

# @ECLASS-VARIABLE: WANT_LIBTOOL
# @DESCRIPTION:
# Do you want libtool?  Valid values here are "latest" and "none".
: ${WANT_LIBTOOL:=latest}

# @ECLASS-VARIABLE: _LATEST_AUTOMAKE
# @INTERNAL
# @DESCRIPTION:
# CONSTANT!
# The latest major version/slot of automake available on each arch.  #312315
# If a newer slot is stable on any arch, and is NOT reflected in this list,
# then circular dependencies may arise during emerge @system bootstraps.
# Do NOT change this variable in your ebuilds!
# If you want to force a newer minor version, you can specify the correct
# WANT value by using a colon:  <PV>[:<WANT_AUTOMAKE>]
_LATEST_AUTOMAKE=( 1.11.1:1.11 )

_automake_atom="sys-devel/automake"
_autoconf_atom="sys-devel/autoconf"
if [[ -n ${WANT_AUTOMAKE} ]]; then
	case ${WANT_AUTOMAKE} in
		none)   _automake_atom="" ;; # some packages don't require automake at all
		# if you change the "latest" version here, change also autotools_run_tool
		# this MUST reflect the latest stable major version for each arch!
		latest)
			# Use SLOT deps if we can.  For EAPI=0, we get pretty close.
			if [[ ${EAPI:-0} != 0 ]] ; then
				_automake_atom="|| ( `printf '>=sys-devel/automake-%s:%s ' ${_LATEST_AUTOMAKE[@]/:/ }` )"
			else
				_automake_atom="|| ( `printf '>=sys-devel/automake-%s ' ${_LATEST_AUTOMAKE[@]/%:*}` )"
			fi
			;;
		*)      _automake_atom="=sys-devel/automake-${WANT_AUTOMAKE}*" ;;
	esac
	export WANT_AUTOMAKE
fi

if [[ -n ${WANT_AUTOCONF} ]] ; then
	case ${WANT_AUTOCONF} in
		none)       _autoconf_atom="" ;; # some packages don't require autoconf at all
		2.1)        _autoconf_atom="=sys-devel/autoconf-${WANT_AUTOCONF}*" ;;
		# if you change the "latest" version here, change also autotools_env_setup
		latest|2.5) _autoconf_atom=">=sys-devel/autoconf-2.68" ;;
		*)          die "Invalid WANT_AUTOCONF value '${WANT_AUTOCONF}'" ;;
	esac
	export WANT_AUTOCONF
fi

_libtool_atom="sys-devel/libtool"
if [[ -n ${WANT_LIBTOOL} ]] ; then
	case ${WANT_LIBTOOL} in
		none)   _libtool_atom="" ;;
		latest) ;;
		*)      die "Invalid WANT_LIBTOOL value '${WANT_LIBTOOL}'" ;;
	esac
	export WANT_LIBTOOL
fi

AUTOTOOLS_DEPEND="${_automake_atom} ${_autoconf_atom} ${_libtool_atom}"
RDEPEND=""

# @ECLASS-VARIABLE: AUTOTOOLS_AUTO_DEPEND
# @DESCRIPTION:
# Set to 'no' to disable automatically adding to DEPEND.  This lets
# ebuilds former conditional depends by using ${AUTOTOOLS_DEPEND} in
# their own DEPEND string.
: ${AUTOTOOLS_AUTO_DEPEND:=yes}
if [[ ${AUTOTOOLS_AUTO_DEPEND} != "no" ]] ; then
	DEPEND=${AUTOTOOLS_DEPEND}
fi

unset _automake_atom _autoconf_atom

# @ECLASS-VARIABLE: AM_OPTS
# @DEFAULT_UNSET
# @DESCRIPTION:
# Additional options to pass to automake during
# eautoreconf call.

# @ECLASS-VARIABLE: AT_NOEAUTOMAKE
# @DEFAULT_UNSET
# @DESCRIPTION:
# Don't run eautomake command if set to 'yes'; only used to workaround
# broken packages.  Generally you should, instead, fix the package to
# not call AM_INIT_AUTOMAKE if it doesn't actually use automake.

# @ECLASS-VARIABLE: AT_NOELIBTOOLIZE
# @DEFAULT_UNSET
# @DESCRIPTION:
# Don't run elibtoolize command if set to 'yes',
# useful when elibtoolize needs to be ran with
# particular options

# @ECLASS-VARIABLE: AT_M4DIR
# @DESCRIPTION:
# Additional director(y|ies) aclocal should search
: ${AT_M4DIR:=}

# @ECLASS-VARIABLE: AT_SYS_M4DIR
# @INTERNAL
# @DESCRIPTION:
# For system integrators, a list of additional aclocal search paths.
# This variable gets eval-ed, so you can use variables in the definition
# that may not be valid until eautoreconf & friends are run.
: ${AT_SYS_M4DIR:=}

# @FUNCTION: eautoreconf
# @DESCRIPTION:
# This function mimes the behavior of autoreconf, but uses the different
# eauto* functions to run the tools. It doesn't accept parameters, but
# the directory with include files can be specified with AT_M4DIR variable.
#
# Should do a full autoreconf - normally what most people will be interested in.
# Also should handle additional directories specified by AC_CONFIG_SUBDIRS.
eautoreconf() {
	local x auxdir g

	if [[ -z ${AT_NO_RECURSIVE} ]]; then
		# Take care of subdirs
		for x in $(autotools_get_subdirs); do
			if [[ -d ${x} ]] ; then
				pushd "${x}" >/dev/null
				AT_NOELIBTOOLIZE="yes" eautoreconf
				popd >/dev/null
			fi
		done
	fi

	auxdir=$(autotools_get_auxdir)

	einfo "Running eautoreconf in '${PWD}' ..."
	[[ -n ${auxdir} ]] && mkdir -p ${auxdir}
	eaclocal
	[[ ${CHOST} == *-darwin* ]] && g=g
	if ${LIBTOOLIZE:-${g}libtoolize} -n --install >& /dev/null ; then
		_elibtoolize --copy --force --install
	else
		_elibtoolize --copy --force
	fi
	eautoconf
	eautoheader
	[[ ${AT_NOEAUTOMAKE} != "yes" ]] && FROM_EAUTORECONF="yes" eautomake ${AM_OPTS}

	[[ ${AT_NOELIBTOOLIZE} == "yes" ]] && return 0

	# Call it here to prevent failures due to elibtoolize called _before_
	# eautoreconf.  We set $S because elibtoolize runs on that #265319
	S=${PWD} elibtoolize --force

	return 0
}

# @FUNCTION: eaclocal_amflags
# @DESCRIPTION:
# Extract the ACLOCAL_AMFLAGS value from the Makefile.am and try to handle
# (most) of the crazy crap that people throw at us.
eaclocal_amflags() {
	local aclocal_opts amflags_file

	for amflags_file in GNUmakefile.am Makefile.am GNUmakefile.in Makefile.in ; do
		[[ -e ${amflags_file} ]] || continue
		# setup the env in case the pkg does something crazy
		# in their ACLOCAL_AMFLAGS.  like run a shell script
		# which turns around and runs autotools. #365401
		# or split across multiple lines. #383525
		autotools_env_setup
		aclocal_opts=$(sed -n \
			"/^ACLOCAL_AMFLAGS[[:space:]]*=/{ \
			  # match the first line
			  s:[^=]*=::p; \
			  # then gobble up all escaped lines
			  : nextline /\\\\$/{ n; p; b nextline; } \
			}" ${amflags_file})
		eval aclocal_opts=\""${aclocal_opts}"\"
		break
	done

	echo ${aclocal_opts}
}

# @FUNCTION: eaclocal
# @DESCRIPTION:
# These functions runs the autotools using autotools_run_tool with the
# specified parametes. The name of the tool run is the same of the function
# without e prefix.
# They also force installing the support files for safety.
# Respects AT_M4DIR for additional directories to search for macro's.
eaclocal() {
	[[ ! -f aclocal.m4 || -n $(grep -e 'generated.*by aclocal' aclocal.m4) ]] && \
		autotools_run_tool --at-m4flags aclocal "$@" $(eaclocal_amflags)
}

# @FUNCTION: _elibtoolize
# @DESCRIPTION:
# Runs libtoolize.  Note the '_' prefix .. to not collide with elibtoolize() from
# libtool.eclass.
_elibtoolize() {
	local opts g=

	# Check if we should run libtoolize (AM_PROG_LIBTOOL is an older macro,
	# check for both it and the current AC_PROG_LIBTOOL)
	[[ -n $(autotools_check_macro AC_PROG_LIBTOOL AM_PROG_LIBTOOL LT_INIT) ]] || return 0

	[[ -f GNUmakefile.am || -f Makefile.am ]] && opts="--automake"

	[[ ${CHOST} == *-darwin* ]] && g=g
	autotools_run_tool ${LIBTOOLIZE:-${g}libtoolize} "$@" ${opts}

	# Need to rerun aclocal
	eaclocal
}

# @FUNCTION: eautoheader
# @DESCRIPTION:
# Runs autoheader.
eautoheader() {
	# Check if we should run autoheader
	[[ -n $(autotools_check_macro "AC_CONFIG_HEADERS") ]] || return 0
	autotools_run_tool --at-no-fail --at-m4flags autoheader "$@"
}

# @FUNCTION: eautoconf
# @DESCRIPTION:
# Runs autoconf.
eautoconf() {
	if [[ ! -f configure.ac && ! -f configure.in ]] ; then
		echo
		eerror "No configure.{ac,in} present in '${PWD}'!"
		echo
		die "No configure.{ac,in} present!"
	fi

	autotools_run_tool --at-m4flags autoconf "$@"
}

# @FUNCTION: eautomake
# @DESCRIPTION:
# Runs automake.
eautomake() {
	local extra_opts
	local makefile_name

	# Run automake if:
	#  - a Makefile.am type file exists
	#  - the configure script is using the AM_INIT_AUTOMAKE directive
	for makefile_name in {GNUmakefile,{M,m}akefile}.am "" ; do
		[[ -f ${makefile_name} ]] && break
	done

	if [[ -z ${makefile_name} ]] ; then
		# Really we should just use autotools_check_macro ...
		local am_init_automake=$(sed -n '/AM_INIT_AUTOMAKE/{s:#.*::;s:\<dnl\>.*::;p}' configure.??)
		if [[ ${am_init_automake} != *"AM_INIT_AUTOMAKE"* ]] ; then
			return 0
		fi

	elif [[ -z ${FROM_EAUTORECONF} && -f ${makefile_name%.am}.in ]]; then
		local used_automake
		local installed_automake

		installed_automake=$(WANT_AUTOMAKE= automake --version | head -n 1 | \
			sed -e 's:.*(GNU automake) ::')
		used_automake=$(head -n 1 < ${makefile_name%.am}.in | \
			sed -e 's:.*by automake \(.*\) from .*:\1:')

		if [[ ${installed_automake} != ${used_automake} ]]; then
			einfo "Automake used for the package (${used_automake}) differs from"
			einfo "the installed version (${installed_automake})."
			eautoreconf
			return 0
		fi
	fi

	[[ -f INSTALL && -f AUTHORS && -f ChangeLog && -f NEWS && -f README ]] \
		|| extra_opts="${extra_opts} --foreign"

	# --force-missing seems not to be recognized by some flavours of automake
	autotools_run_tool automake --add-missing --copy ${extra_opts} "$@"
}

# @FUNCTION: eautopoint
# @DESCRIPTION:
# Runs autopoint (from the gettext package).
eautopoint() {
	autotools_run_tool autopoint "$@"
}

# @FUNCTION: config_rpath_update
# @USAGE: [destination]
# @DESCRIPTION:
# Some packages utilize the config.rpath helper script, but don't
# use gettext directly.  So we have to copy it in manually since
# we can't let `autopoint` do it for us.
config_rpath_update() {
	local dst src=$(type -P gettext | sed 's:bin/gettext:share/gettext/config.rpath:')

	[[ $# -eq 0 ]] && set -- $(find -name config.rpath)
	[[ $# -eq 0 ]] && return 0

	einfo "Updating all config.rpath files"
	for dst in "$@" ; do
		einfo "   ${dst}"
		cp "${src}" "${dst}" || die
	done
}

# Internal function to run an autotools' tool
autotools_env_setup() {
	# We do the "latest" → version switch here because it solves
	# possible order problems, see bug #270010 as an example.
	if [[ ${WANT_AUTOMAKE} == "latest" ]]; then
		local pv
		for pv in ${_LATEST_AUTOMAKE[@]/#*:} ; do
			# has_version respects ROOT, but in this case, we don't want it to,
			# thus "ROOT=/" prefix:
			ROOT=/ has_version "=sys-devel/automake-${pv}*" && export WANT_AUTOMAKE="${pv}"
		done
		[[ ${WANT_AUTOMAKE} == "latest" ]] && \
			die "Cannot find the latest automake! Tried ${_LATEST_AUTOMAKE}"
	fi
	[[ ${WANT_AUTOCONF} == "latest" ]] && export WANT_AUTOCONF=2.5
}
autotools_run_tool() {
	# Process our own internal flags first
	local autofail=true m4flags=false
	while [[ -n $1 ]] ; do
		case $1 in
		--at-no-fail) autofail=false;;
		--at-m4flags) m4flags=true;;
		# whatever is left goes to the actual tool
		*) break;;
		esac
		shift
	done

	if [[ ${EBUILD_PHASE} != "unpack" && ${EBUILD_PHASE} != "prepare" ]]; then
		ewarn "QA Warning: running $1 in ${EBUILD_PHASE} phase"
	fi

	autotools_env_setup

	local STDERR_TARGET="${T}/$1.out"
	# most of the time, there will only be one run, but if there are
	# more, make sure we get unique log filenames
	if [[ -e ${STDERR_TARGET} ]] ; then
		local i=1
		while :; do
			STDERR_TARGET="${T}/$1-${i}.out"
			[[ -e ${STDERR_TARGET} ]] || break
			: $(( i++ ))
		done
	fi

	if ${m4flags} ; then
		set -- "${1}" $(autotools_m4dir_include) "${@:2}" $(autotools_m4sysdir_include)
	fi

	printf "***** $1 *****\n***** PWD: ${PWD}\n***** $*\n\n" > "${STDERR_TARGET}"

	ebegin "Running $@"
	"$@" >> "${STDERR_TARGET}" 2>&1
	if ! eend $? && ${autofail} ; then
		echo
		eerror "Failed Running $1 !"
		eerror
		eerror "Include in your bugreport the contents of:"
		eerror
		eerror "  ${STDERR_TARGET}"
		echo
		die "Failed Running $1 !"
	fi
}

# Internal function to check for support
autotools_check_macro() {
	[[ -f configure.ac || -f configure.in ]] || return 0
	local macro
	for macro ; do
		WANT_AUTOCONF="2.5" autoconf $(autotools_m4dir_include) --trace="${macro}" 2>/dev/null
	done
	return 0
}

# Internal function to look for a macro and extract its value
autotools_check_macro_val() {
	local macro=$1 scan_out

	autotools_check_macro "${macro}" | \
		gawk -v macro="${macro}" \
			'($0 !~ /^[[:space:]]*(#|dnl)/) {
				if (match($0, macro ":(.*)$", res))
					print res[1]
			}' | uniq

	return 0
}

# Internal function to get additional subdirs to configure
autotools_get_subdirs() { autotools_check_macro_val AC_CONFIG_SUBDIRS ; }
autotools_get_auxdir() { autotools_check_macro_val AC_CONFIG_AUX_DIR ; }

_autotools_m4dir_include() {
	local x include_opts

	for x in "$@" ; do
		case ${x} in
			# We handle it below
			-I) ;;
			*)
				[[ ! -d ${x} ]] && ewarn "autotools.eclass: '${x}' does not exist"
				include_opts+=" -I ${x}"
				;;
		esac
	done

	echo ${include_opts}
}
autotools_m4dir_include()    { _autotools_m4dir_include ${AT_M4DIR} ; }
autotools_m4sysdir_include() { _autotools_m4dir_include $(eval echo ${AT_SYS_M4DIR}) ; }

fi
