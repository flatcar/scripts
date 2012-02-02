# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/rpm.eclass,v 1.19 2009/10/05 06:14:36 vapier Exp $

# @ECLASS: rpm.eclass
# @MAINTAINER:
# base-system@gentoo.org
# @BLURB: convenience class for extracting RPMs

inherit eutils

DEPEND=">=app-arch/rpm2targz-9.0.0.3g"

# @FUNCTION: rpm_unpack
# @USAGE: <rpms>
# @DESCRIPTION:
# Unpack the contents of the specified rpms like the unpack() function.
rpm_unpack() {
	[[ $# -eq 0 ]] && set -- ${A}
	local a
	for a in "$@" ; do
		echo ">>> Unpacking ${a} to ${PWD}"
		if [[ ${a} == ./* ]] ; then
			: nothing to do -- path is local
		elif [[ ${a} == ${DISTDIR}/* ]] ; then
			ewarn 'QA: do not use ${DISTDIR} with rpm_unpack -- it is added for you'
		elif [[ ${a} == /* ]] ; then
			ewarn 'QA: do not use full paths with rpm_unpack -- use ./ paths instead'
		else
			a="${DISTDIR}/${a}"
		fi
		rpm2tar -O "${a}" | tar xf - || die "failure unpacking ${a}"
	done
}

# @FUNCTION: srcrpm_unpack
# @USAGE: <rpms>
# @DESCRIPTION:
# Unpack the contents of the specified rpms like the unpack() function as well
# as any archives that it might contain.  Note that the secondary archive
# unpack isn't perfect in that it simply unpacks all archives in the working
# directory (with the assumption that there weren't any to start with).
srcrpm_unpack() {
	[[ $# -eq 0 ]] && set -- ${A}
	rpm_unpack "$@"

	# no .src.rpm files, then nothing to do
	[[ "$* " != *".src.rpm " ]] && return 0

	local old_shopts=$(shopt -p nullglob)
	shopt -s nullglob

	# unpack everything
	local a
	for a in *.tar.{gz,bz2} *.t{gz,bz2} *.zip *.ZIP ; do
		unpack "./${a}"
		rm -f "${a}"
	done

	eval "${old_shopts}"

	return 0
}

# @FUNCTION: rpm_src_unpack
# @DESCRIPTION:
# Automatically unpack all archives in ${A} including rpms.  If one of the
# archives in a source rpm, then the sub archives will be unpacked as well.
rpm_src_unpack() {
	local a
	for a in ${A} ; do
		case ${a} in
		*.rpm) srcrpm_unpack "${a}" ;;
		*)     unpack "${a}" ;;
		esac
	done
}

# @FUNCTION: rpm_spec_epatch
# @USAGE: [spec]
# @DESCRIPTION:
# Read the specified spec (defaults to ${PN}.spec) and attempt to apply
# all the patches listed in it.  If the spec does funky things like moving
# files around, well this won't handle that.
rpm_spec_epatch() {
	local p spec=${1:-${PN}.spec}
	local dir=${spec%/*}
	grep '^%patch' "${spec}" | \
	while read line ; do
		set -- ${line}
		p=$1
		shift
		EPATCH_OPTS="$*"
		set -- $(grep "^P${p#%p}: " "${spec}")
		shift
		epatch "${dir:+${dir}/}$*"
	done
}

EXPORT_FUNCTIONS src_unpack
