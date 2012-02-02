# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/flag-o-matic.eclass,v 1.146 2010/02/17 18:20:49 ssuominen Exp $

# @ECLASS: flag-o-matic.eclass
# @MAINTAINER:
# toolchain@gentoo.org
# @BLURB: common functions to manipulate and query toolchain flags
# @DESCRIPTION:
# This eclass contains a suite of functions to help developers sanely
# and safely manage toolchain flags in their builds.

inherit eutils toolchain-funcs multilib

################ DEPRECATED functions ################
# The following are still present to avoid breaking existing
# code more than necessary; however they are deprecated. Please
# use gcc-specs-* from toolchain-funcs.eclass instead, if you
# need to know which hardened techs are active in the compiler.
# See bug #100974
#
# has_hardened
# has_pie
# has_pic
# has_ssp_all
# has_ssp


# {C,CXX,F,FC}FLAGS that we allow in strip-flags
# Note: shell globs and character lists are allowed
setup-allowed-flags() {
	if [[ -z ${ALLOWED_FLAGS} ]] ; then
		export ALLOWED_FLAGS="-pipe"
		export ALLOWED_FLAGS="${ALLOWED_FLAGS} -O -O0 -O1 -O2 -mcpu -march -mtune"
		export ALLOWED_FLAGS="${ALLOWED_FLAGS} -fstack-protector -fstack-protector-all"
		export ALLOWED_FLAGS="${ALLOWED_FLAGS} -fbounds-checking -fno-strict-overflow"
		export ALLOWED_FLAGS="${ALLOWED_FLAGS} -fno-PIE -fno-pie -fno-unit-at-a-time"
		export ALLOWED_FLAGS="${ALLOWED_FLAGS} -g -g[0-9] -ggdb -ggdb[0-9] -gstabs -gstabs+"
		export ALLOWED_FLAGS="${ALLOWED_FLAGS} -fno-ident"
		export ALLOWED_FLAGS="${ALLOWED_FLAGS} -W* -w"
	fi
	# allow a bunch of flags that negate features / control ABI
	ALLOWED_FLAGS="${ALLOWED_FLAGS} -fno-stack-protector -fno-stack-protector-all \
		-fno-strict-aliasing -fno-bounds-checking -fstrict-overflow -fno-omit-frame-pointer"
	ALLOWED_FLAGS="${ALLOWED_FLAGS} -mregparm -mno-app-regs -mapp-regs \
		-mno-mmx -mno-sse -mno-sse2 -mno-sse3 -mno-ssse3 -mno-sse4 -mno-sse4.1 \
		-mno-sse4.2 -mno-avx -mno-aes -mno-pclmul -mno-sse4a -mno-3dnow \
		-mno-popcnt -mno-abm \
		-mips1 -mips2 -mips3 -mips4 -mips32 -mips64 -mips16 -mplt \
		-msoft-float -mno-soft-float -mhard-float -mno-hard-float -mfpu \
		-mieee -mieee-with-inexact -mschedule \
		-mtls-direct-seg-refs -mno-tls-direct-seg-refs \
		-mflat -mno-flat -mno-faster-structs -mfaster-structs \
		-m32 -m64 -mabi -mlittle-endian -mbig-endian -EL -EB -fPIC \
		-mlive-g0 -mcmodel -mstack-bias -mno-stack-bias \
		-msecure-plt -m*-toc -D* -U*"

	# {C,CXX,F,FC}FLAGS that we are think is ok, but needs testing
	# NOTE:  currently -Os have issues with gcc3 and K6* arch's
	export UNSTABLE_FLAGS="-Os -O3 -freorder-blocks"
	return 0
}

# inverted filters for hardened compiler.  This is trying to unpick
# the hardened compiler defaults.
_filter-hardened() {
	local f
	for f in "$@" ; do
		case "${f}" in
			# Ideally we should only concern ourselves with PIE flags,
			# not -fPIC or -fpic, but too many places filter -fPIC without
			# thinking about -fPIE.
			-fPIC|-fpic|-fPIE|-fpie|-Wl,pie|-pie)
				gcc-specs-pie || continue
				is-flagq -nopie || append-flags -nopie;;
			-fstack-protector)
				gcc-specs-ssp || continue
				is-flagq -fno-stack-protector || append-flags $(test-flags -fno-stack-protector);;
			-fstack-protector-all)
				gcc-specs-ssp-to-all || continue
				is-flagq -fno-stack-protector-all || append-flags $(test-flags -fno-stack-protector-all);;
			-fno-strict-overflow)
				gcc-specs-nostrict || continue
				is-flagq -fstrict-overflow || append-flags $(test-flags -fstrict-overflow);;
		esac
	done
}

# Remove occurrences of strings from variable given in $1
# Strings removed are matched as globs, so for example
# '-O*' would remove -O1, -O2 etc.
_filter-var() {
	local f x VAR VAL
	declare -a new

	VAR=$1
	shift
	eval VAL=\${${VAR}}
	for f in ${VAL}; do
		for x in "$@"; do
			# Note this should work with globs like -O*
			[[ ${f} == ${x} ]] && continue 2
		done
		eval new\[\${\#new\[@]}]=\${f}
	done
	eval export ${VAR}=\${new\[*]}
}

# @FUNCTION: filter-flags
# @USAGE: <flags>
# @DESCRIPTION:
# Remove particular <flags> from {C,CPP,CXX,F,FC}FLAGS.  Accepts shell globs.
filter-flags() {
	_filter-hardened "$@"
	_filter-var CFLAGS "$@"
	_filter-var CPPFLAGS "$@"
	_filter-var CXXFLAGS "$@"
	_filter-var FFLAGS "$@"
	_filter-var FCFLAGS "$@"
	return 0
}

# @FUNCTION: filter-lfs-flags
# @DESCRIPTION:
# Remove flags that enable Large File Support.
filter-lfs-flags() {
	[[ -n $@ ]] && die "filter-lfs-flags takes no arguments"
	filter-flags -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE
}

# @FUNCTION: append-cppflags
# @USAGE: <flags>
# @DESCRIPTION:
# Add extra <flags> to the current CPPFLAGS.
append-cppflags() {
	[[ -z $* ]] && return 0
	export CPPFLAGS="${CPPFLAGS} $*"
	return 0
}

# @FUNCTION: append-cflags
# @USAGE: <flags>
# @DESCRIPTION:
# Add extra <flags> to the current CFLAGS.
append-cflags() {
	[[ -z $* ]] && return 0
	export CFLAGS="${CFLAGS} $*"
	return 0
}

# @FUNCTION: append-cxxflags
# @USAGE: <flags>
# @DESCRIPTION:
# Add extra <flags> to the current CXXFLAGS.
append-cxxflags() {
	[[ -z $* ]] && return 0
	export CXXFLAGS="${CXXFLAGS} $*"
	return 0
}

# @FUNCTION: append-fflags
# @USAGE: <flags>
# @DESCRIPTION:
# Add extra <flags> to the current {F,FC}FLAGS.
append-fflags() {
	[[ -z $* ]] && return 0
	export FFLAGS="${FFLAGS} $*"
	export FCFLAGS="${FCFLAGS} $*"
	return 0
}

# @FUNCTION: append-lfs-flags
# @DESCRIPTION:
# Add flags that enable Large File Support.
append-lfs-flags() {
	[[ -n $@ ]] && die "append-lfs-flags takes no arguments"
	append-cppflags -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE
}

# @FUNCTION: append-flags
# @USAGE: <flags>
# @DESCRIPTION:
# Add extra <flags> to your current {C,CXX,F,FC}FLAGS.
append-flags() {
	[[ -z $* ]] && return 0
	append-cflags "$@"
	append-cxxflags "$@"
	append-fflags "$@"
	return 0
}

# @FUNCTION: replace-flags
# @USAGE: <old> <new>
# @DESCRIPTION:
# Replace the <old> flag with <new>.  Accepts shell globs for <old>.
replace-flags() {
	[[ $# != 2 ]] \
		&& echo && eerror "Usage: replace-flags <old flag> <new flag>" \
		&& die "replace-flags takes 2 arguments, not $#"

	local f fset
	declare -a new_CFLAGS new_CXXFLAGS new_FFLAGS new_FCFLAGS

	for fset in CFLAGS CXXFLAGS FFLAGS FCFLAGS; do
		# Looping over the flags instead of using a global
		# substitution ensures that we're working with flag atoms.
		# Otherwise globs like -O* have the potential to wipe out the
		# list of flags.
		for f in ${!fset}; do
			# Note this should work with globs like -O*
			[[ ${f} == ${1} ]] && f=${2}
			eval new_${fset}\[\${\#new_${fset}\[@]}]=\${f}
		done
		eval export ${fset}=\${new_${fset}\[*]}
	done

	return 0
}

# @FUNCTION: replace-cpu-flags
# @USAGE: <old> <new>
# @DESCRIPTION:
# Replace cpu flags (like -march/-mcpu/-mtune) that select the <old> cpu
# with flags that select the <new> cpu.  Accepts shell globs for <old>.
replace-cpu-flags() {
	local newcpu="$#" ; newcpu="${!newcpu}"
	while [ $# -gt 1 ] ; do
		# quote to make sure that no globbing is done (particularly on
		# ${oldcpu}) prior to calling replace-flags
		replace-flags "-march=${1}" "-march=${newcpu}"
		replace-flags "-mcpu=${1}" "-mcpu=${newcpu}"
		replace-flags "-mtune=${1}" "-mtune=${newcpu}"
		shift
	done
	return 0
}

_is_flagq() {
	local x
	for x in ${!1} ; do
		[[ ${x} == $2 ]] && return 0
	done
	return 1
}

# @FUNCTION: is-flagq
# @USAGE: <flag>
# @DESCRIPTION:
# Returns shell true if <flag> is in {C,CXX,F,FC}FLAGS, else returns shell false.  Accepts shell globs.
is-flagq() {
	[[ -n $2 ]] && die "Usage: is-flag <flag>"
	_is_flagq CFLAGS $1 || _is_flagq CXXFLAGS $1 || _is_flagq FFLAGS $1 || _is_flagq FCFLAGS $1
}

# @FUNCTION: is-flag
# @USAGE: <flag>
# @DESCRIPTION:
# Echo's "true" if flag is set in {C,CXX,F,FC}FLAGS.  Accepts shell globs.
is-flag() {
	is-flagq "$@" && echo true
}

# @FUNCTION: is-ldflagq
# @USAGE: <flag>
# @DESCRIPTION:
# Returns shell true if <flag> is in LDFLAGS, else returns shell false.  Accepts shell globs.
is-ldflagq() {
	[[ -n $2 ]] && die "Usage: is-ldflag <flag>"
	_is_flagq LDFLAGS $1
}

# @FUNCTION: is-ldflag
# @USAGE: <flag>
# @DESCRIPTION:
# Echo's "true" if flag is set in LDFLAGS.  Accepts shell globs.
is-ldflag() {
	is-ldflagq "$@" && echo true
}

# @FUNCTION: filter-mfpmath
# @USAGE: <math types>
# @DESCRIPTION:
# Remove specified math types from the fpmath flag.  For example, if the user
# has -mfpmath=sse,386, running `filter-mfpmath sse` will leave the user with
# -mfpmath=386.
filter-mfpmath() {
	local orig_mfpmath new_math prune_math

	# save the original -mfpmath flag
	orig_mfpmath=$(get-flag -mfpmath)
	# get the value of the current -mfpmath flag
	new_math=$(get-flag mfpmath)
	new_math=" ${new_math//,/ } "
	# figure out which math values are to be removed
	prune_math=""
	for prune_math in "$@" ; do
		new_math=${new_math/ ${prune_math} / }
	done
	new_math=$(echo ${new_math})
	new_math=${new_math// /,}

	if [[ -z ${new_math} ]] ; then
		# if we're removing all user specified math values are
		# slated for removal, then we just filter the flag
		filter-flags ${orig_mfpmath}
	else
		# if we only want to filter some of the user specified
		# math values, then we replace the current flag
		replace-flags ${orig_mfpmath} -mfpmath=${new_math}
	fi
	return 0
}

# @FUNCTION: strip-flags
# @DESCRIPTION:
# Strip C[XX]FLAGS of everything except known good/safe flags.
strip-flags() {
	local x y flag NEW_CFLAGS NEW_CXXFLAGS NEW_FFLAGS NEW_FCFLAGS

	setup-allowed-flags

	local NEW_CFLAGS=""
	local NEW_CXXFLAGS=""
	local NEW_FFLAGS=""
	local NEW_FCFLAGS=""

	# Allow unstable C[XX]FLAGS if we are using unstable profile ...
	if has "~$(tc-arch)" ${ACCEPT_KEYWORDS} ; then
		ALLOWED_FLAGS="${ALLOWED_FLAGS} ${UNSTABLE_FLAGS}"
	fi

	set -f	# disable pathname expansion

	for x in ${CFLAGS}; do
		for y in ${ALLOWED_FLAGS}; do
			flag=${x%%=*}
			if [ "${flag%%${y}}" = "" ] ; then
				NEW_CFLAGS="${NEW_CFLAGS} ${x}"
				break
			fi
		done
	done

	for x in ${CXXFLAGS}; do
		for y in ${ALLOWED_FLAGS}; do
			flag=${x%%=*}
			if [ "${flag%%${y}}" = "" ] ; then
				NEW_CXXFLAGS="${NEW_CXXFLAGS} ${x}"
				break
			fi
		done
	done

	for x in ${FFLAGS}; do
		for y in ${ALLOWED_FLAGS}; do
			flag=${x%%=*}
			if [ "${flag%%${y}}" = "" ] ; then
				NEW_FFLAGS="${NEW_FFLAGS} ${x}"
				break
			fi
		done
	done

	for x in ${FCFLAGS}; do
		for y in ${ALLOWED_FLAGS}; do
			flag=${x%%=*}
			if [ "${flag%%${y}}" = "" ] ; then
				NEW_FCFLAGS="${NEW_FCFLAGS} ${x}"
				break
			fi
		done
	done

	# In case we filtered out all optimization flags fallback to -O2
	if [ "${CFLAGS/-O}" != "${CFLAGS}" -a "${NEW_CFLAGS/-O}" = "${NEW_CFLAGS}" ]; then
		NEW_CFLAGS="${NEW_CFLAGS} -O2"
	fi
	if [ "${CXXFLAGS/-O}" != "${CXXFLAGS}" -a "${NEW_CXXFLAGS/-O}" = "${NEW_CXXFLAGS}" ]; then
		NEW_CXXFLAGS="${NEW_CXXFLAGS} -O2"
	fi
	if [ "${FFLAGS/-O}" != "${FFLAGS}" -a "${NEW_FFLAGS/-O}" = "${NEW_FFLAGS}" ]; then
		NEW_FFLAGS="${NEW_FFLAGS} -O2"
	fi
	if [ "${FCFLAGS/-O}" != "${FCFLAGS}" -a "${NEW_FCFLAGS/-O}" = "${NEW_FCFLAGS}" ]; then
		NEW_FCFLAGS="${NEW_FCFLAGS} -O2"
	fi

	set +f	# re-enable pathname expansion

	export CFLAGS="${NEW_CFLAGS}"
	export CXXFLAGS="${NEW_CXXFLAGS}"
	export FFLAGS="${NEW_FFLAGS}"
	export FCFLAGS="${NEW_FCFLAGS}"
	return 0
}

test-flag-PROG() {
	local comp=$1
	local flags="$2"

	[[ -z ${comp} || -z ${flags} ]] && \
		return 1

	local PROG=$(tc-get${comp})
	${PROG} ${flags} -S -o /dev/null -xc /dev/null \
		> /dev/null 2>&1
}

# @FUNCTION: test-flag-CC
# @USAGE: <flag>
# @DESCRIPTION:
# Returns shell true if <flag> is supported by the C compiler, else returns shell false.
test-flag-CC() { test-flag-PROG "CC" "$1"; }

# @FUNCTION: test-flag-CXX
# @USAGE: <flag>
# @DESCRIPTION:
# Returns shell true if <flag> is supported by the C++ compiler, else returns shell false.
test-flag-CXX() { test-flag-PROG "CXX" "$1"; }

# @FUNCTION: test-flag-F77
# @USAGE: <flag>
# @DESCRIPTION:
# Returns shell true if <flag> is supported by the Fortran 77 compiler, else returns shell false.
test-flag-F77() { test-flag-PROG "F77" "$1"; }

# @FUNCTION: test-flag-FC
# @USAGE: <flag>
# @DESCRIPTION:
# Returns shell true if <flag> is supported by the Fortran 90 compiler, else returns shell false.
test-flag-FC() { test-flag-PROG "FC" "$1"; }

test-flags-PROG() {
	local comp=$1
	local flags
	local x

	shift

	[[ -z ${comp} ]] && return 1

	x=""
	for x in "$@" ; do
		test-flag-${comp} "${x}" && flags="${flags}${flags:+ }${x}"
	done

	echo "${flags}"

	# Just bail if we dont have any flags
	[[ -n ${flags} ]]
}

# @FUNCTION: test-flags-CC
# @USAGE: <flags>
# @DESCRIPTION:
# Returns shell true if <flags> are supported by the C compiler, else returns shell false.
test-flags-CC() { test-flags-PROG "CC" "$@"; }

# @FUNCTION: test-flags-CXX
# @USAGE: <flags>
# @DESCRIPTION:
# Returns shell true if <flags> are supported by the C++ compiler, else returns shell false.
test-flags-CXX() { test-flags-PROG "CXX" "$@"; }

# @FUNCTION: test-flags-F77
# @USAGE: <flags>
# @DESCRIPTION:
# Returns shell true if <flags> are supported by the Fortran 77 compiler, else returns shell false.
test-flags-F77() { test-flags-PROG "F77" "$@"; }

# @FUNCTION: test-flags-FC
# @USAGE: <flags>
# @DESCRIPTION:
# Returns shell true if <flags> are supported by the Fortran 90 compiler, else returns shell false.
test-flags-FC() { test-flags-PROG "FC" "$@"; }

# @FUNCTION: test-flags
# @USAGE: <flags>
# @DESCRIPTION:
# Short-hand that should hopefully work for both C and C++ compiler, but
# its really only present due to the append-flags() abomination.
test-flags() { test-flags-CC "$@"; }

# @FUNCTION: test_flag
# @DESCRIPTION:
# DEPRICIATED, use test-flags()
test_flag() {
	ewarn "test_flag: deprecated, please use test-flags()!" >&2

	test-flags-CC "$@"
}

# @FUNCTION: test_version_info
# @USAGE: <version>
# @DESCRIPTION:
# Returns shell true if the current C compiler version matches <version>, else returns shell false.
# Accepts shell globs.
test_version_info() {
	if [[ $($(tc-getCC) --version 2>&1) == *$1* ]]; then
		return 0
	else
		return 1
	fi
}

# @FUNCTION: strip-unsupported-flags
# @DESCRIPTION:
# Strip {C,CXX,F,FC}FLAGS of any flags not supported by the active toolchain.
strip-unsupported-flags() {
	export CFLAGS=$(test-flags-CC ${CFLAGS})
	export CXXFLAGS=$(test-flags-CXX ${CXXFLAGS})
	export FFLAGS=$(test-flags-F77 ${FFLAGS})
	export FCFLAGS=$(test-flags-FC ${FCFLAGS})
}

# @FUNCTION: get-flag
# @USAGE: <flag>
# @DESCRIPTION:
# Find and echo the value for a particular flag.  Accepts shell globs.
get-flag() {
	local f findflag="$1"

	# this code looks a little flaky but seems to work for
	# everything we want ...
	# for example, if CFLAGS="-march=i686":
	# `get-flag -march` == "-march=i686"
	# `get-flag march` == "i686"
	for f in ${CFLAGS} ${CXXFLAGS} ${FFLAGS} ${FCFLAGS} ; do
		if [ "${f/${findflag}}" != "${f}" ] ; then
			printf "%s\n" "${f/-${findflag}=}"
			return 0
		fi
	done
	return 1
}

# @FUNCTION: has_hardened
# @DESCRIPTION:
# DEPRECATED - use gcc-specs-relro or gcc-specs-now from toolchain-funcs
has_hardened() {
	ewarn "has_hardened: deprecated, please use gcc-specs-{relro,now}()!" >&2

	test_version_info Hardened && return 0
	# The specs file wont exist unless gcc has GCC_SPECS support
	[[ -f ${GCC_SPECS} && ${GCC_SPECS} != ${GCC_SPECS/hardened/} ]]
}

# @FUNCTION: has_pic
# @DESCRIPTION:
# DEPRECATED - use gcc-specs-pie from toolchain-funcs
# indicate whether PIC is set
has_pic() {
	ewarn "has_pic: deprecated, please use gcc-specs-pie()!" >&2

	[[ ${CFLAGS/-fPIC} != ${CFLAGS} || \
	   ${CFLAGS/-fpic} != ${CFLAGS} ]] || \
	gcc-specs-pie
}

# @FUNCTION: has_pie
# @DESCRIPTION:
# DEPRECATED - use gcc-specs-pie from toolchain-funcs
# indicate whether PIE is set
has_pie() {
	ewarn "has_pie: deprecated, please use gcc-specs-pie()!" >&2

	[[ ${CFLAGS/-fPIE} != ${CFLAGS} || \
	   ${CFLAGS/-fpie} != ${CFLAGS} ]] || \
	gcc-specs-pie
}

# @FUNCTION: has_ssp_all
# @DESCRIPTION:
# DEPRECATED - use gcc-specs-ssp from toolchain-funcs
# indicate whether code for SSP is being generated for all functions
has_ssp_all() {
	ewarn "has_ssp_all: deprecated, please use gcc-specs-ssp()!" >&2

	# note; this matches only -fstack-protector-all
	[[ ${CFLAGS/-fstack-protector-all} != ${CFLAGS} || \
	   -n $(echo | $(tc-getCC) ${CFLAGS} -E -dM - | grep __SSP_ALL__) ]] || \
	gcc-specs-ssp-to-all
}

# @FUNCTION: has_ssp
# @DESCRIPTION:
# DEPRECATED - use gcc-specs-ssp from toolchain-funcs
# indicate whether code for SSP is being generated
has_ssp() {
	ewarn "has_ssp: deprecated, please use gcc-specs-ssp()!" >&2

	# note; this matches both -fstack-protector and -fstack-protector-all
	[[ ${CFLAGS/-fstack-protector} != ${CFLAGS} || \
	   -n $(echo | $(tc-getCC) ${CFLAGS} -E -dM - | grep __SSP__) ]] || \
	gcc-specs-ssp
}

# @FUNCTION: has_m64
# @DESCRIPTION:
# This doesn't test if the flag is accepted, it tests if the flag actually
# WORKS. Non-multilib gcc will take both -m32 and -m64. If the flag works
# return code is 0, else the return code is 1.
has_m64() {
	# this doesnt test if the flag is accepted, it tests if the flag
	# actually -WORKS-. non-multilib gcc will take both -m32 and -m64!
	# please dont replace this function with test_flag in some future
	# clean-up!

	local temp="$(emktemp)"
	echo "int main() { return(0); }" > "${temp}".c
	MY_CC=$(tc-getCC)
	${MY_CC/ .*/} -m64 -o "$(emktemp)" "${temp}".c > /dev/null 2>&1
	local ret=$?
	rm -f "${temp}".c
	[[ ${ret} != 1 ]] && return 0
	return 1
}

# @FUNCTION: has_m32
# @DESCRIPTION:
# This doesn't test if the flag is accepted, it tests if the flag actually
# WORKS. Non-mulilib gcc will take both -m32 and -64. If the flag works return
# code is 0, else return code is 1.
has_m32() {
	# this doesnt test if the flag is accepted, it tests if the flag
	# actually -WORKS-. non-multilib gcc will take both -m32 and -m64!
	# please dont replace this function with test_flag in some future
	# clean-up!

	[ "$(tc-arch)" = "amd64" ] && has_multilib_profile && return 0

	local temp=$(emktemp)
	echo "int main() { return(0); }" > "${temp}".c
	MY_CC=$(tc-getCC)
	${MY_CC/ .*/} -m32 -o "$(emktemp)" "${temp}".c > /dev/null 2>&1
	local ret=$?
	rm -f "${temp}".c
	[[ ${ret} != 1 ]] && return 0
	return 1
}

# @FUNCTION: replace-sparc64-flags
# @DESCRIPTION:
# Sets mcpu to v8 and uses the original value as mtune if none specified.
replace-sparc64-flags() {
	local SPARC64_CPUS="ultrasparc3 ultrasparc v9"

	if [ "${CFLAGS/mtune}" != "${CFLAGS}" ]; then
		for x in ${SPARC64_CPUS}; do
			CFLAGS="${CFLAGS/-mcpu=${x}/-mcpu=v8}"
		done
	else
		for x in ${SPARC64_CPUS}; do
			CFLAGS="${CFLAGS/-mcpu=${x}/-mcpu=v8 -mtune=${x}}"
		done
	fi

	if [ "${CXXFLAGS/mtune}" != "${CXXFLAGS}" ]; then
		for x in ${SPARC64_CPUS}; do
			CXXFLAGS="${CXXFLAGS/-mcpu=${x}/-mcpu=v8}"
		done
	else
		for x in ${SPARC64_CPUS}; do
			CXXFLAGS="${CXXFLAGS/-mcpu=${x}/-mcpu=v8 -mtune=${x}}"
		done
	fi

	export CFLAGS CXXFLAGS
}

# @FUNCTION: append-ldflags
# @USAGE: <flags>
# @DESCRIPTION:
# Add extra <flags> to the current LDFLAGS.
append-ldflags() {
	[[ -z $* ]] && return 0
	local flag
	for flag in "$@"; do
		[[ ${flag} == -l* ]] && \
			ewarn "Appending a library link instruction (${flag}); libraries to link to should not be passed through LDFLAGS"
	done

	export LDFLAGS="${LDFLAGS} $*"
	return 0
}

# @FUNCTION: filter-ldflags
# @USAGE: <flags>
# @DESCRIPTION:
# Remove particular <flags> from LDFLAGS.  Accepts shell globs.
filter-ldflags() {
	_filter-var LDFLAGS "$@"
	return 0
}

# @FUNCTION: raw-ldflags
# @USAGE: <flags>
# @DESCRIPTION:
# Turn C style ldflags (-Wl,-foo) into straight ldflags - the results
# are suitable for passing directly to 'ld'; note LDFLAGS is usually passed
# to gcc where it needs the '-Wl,'.
raw-ldflags() {
	local x input="$@"
	[[ -z ${input} ]] && input=${LDFLAGS}
	set --
	for x in ${input} ; do
		x=${x#-Wl,}
		set -- "$@" ${x//,/ }
	done
	echo "$@"
}

# @FUNCTION: no-as-needed
# @RETURN: Flag to disable asneeded behavior for use with append-ldflags.
no-as-needed() {
	case $($(tc-getLD) -v 2>&1 </dev/null) in
		*GNU*) # GNU ld
		echo "-Wl,--no-as-needed" ;;
	esac
}

# Some tests for when we screw with things and want to make
# sure we didn't break anything
#TESTS() {
#	CFLAGS="-a -b -c=1"
#	CXXFLAGS="-x -y -z=2"
#	LDFLAGS="-l -m -n=3"
#
#	die() { exit 1; }
#	(is-flag 1 2 3) && die
#	(is-ldflag 1 2 3) && die
#
#	is-flagq -l && die
#	is-ldflagq -a && die
#	is-flagq -a || die
#	is-flagq -x || die
#	is-ldflagq -n=* || die
#	is-ldflagq -n && die
#
#	strip-unsupported-flags
#	[[ ${CFLAGS} == "-c=1" ]] || die
#	[[ ${CXXFLAGS} == "-y -z=2" ]] || die
#
#	echo "All tests pass"
#}
#TESTS
