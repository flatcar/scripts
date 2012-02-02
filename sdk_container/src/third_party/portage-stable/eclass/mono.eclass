# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/mono.eclass,v 1.13 2009/03/08 15:46:54 loki_val Exp $

# @ECLASS: mono.eclass
# @MAINTAINER:
# dotnet@gentoo.org
# @BLURB: common settings and functions for mono and dotnet related
# packages
# @DESCRIPTION:
# The mono eclass contains common environment settings that are useful for
# dotnet packages.  Currently, it provides no functions, just exports
# MONO_SHARED_DIR and sets LC_ALL in order to prevent errors during compilation
# of dotnet packages.

inherit multilib

# >=mono-0.92 versions using mcs -pkg:foo-sharp require shared memory, so we set the
# shared dir to ${T} so that ${T}/.wapi can be used during the install process.
export MONO_SHARED_DIR="${T}"

# Building mono, nant and many other dotnet packages is known to fail if LC_ALL
# variable is not set to C. To prevent this all mono related packages will be
# build with LC_ALL=C (see bugs #146424, #149817)
export LC_ALL=C

# Monodevelop-using applications need this to be set or they will try to create config
# files in the user's ~ dir.

export XDG_CONFIG_HOME="${T}"

# Fix bug 83020:
# "Access Violations Arise When Emerging Mono-Related Packages with MONO_AOT_CACHE"

unset MONO_AOT_CACHE

egacinstall() {
	gacutil -i "${1}" \
		-root "${D}"/usr/$(get_libdir) \
		-gacdir /usr/$(get_libdir) \
		-package ${2:-${GACPN:-${PN}}} \
		|| die "installing ${1} into the Global Assembly Cache failed"
}

mono_multilib_comply() {
	local dir finddirs=() mv_command=${mv_command:-mv}
	if [[ -d "${D}/usr/lib" && "$(get_libdir)" != "lib" ]]
	then
		if ! [[ -d "${D}"/usr/"$(get_libdir)" ]]
		then
			mkdir "${D}"/usr/"$(get_libdir)" || die "Couldn't mkdir ${D}/usr/$(get_libdir)"
		fi
		${mv_command} "${D}"/usr/lib/* "${D}"/usr/"$(get_libdir)"/ || die "Moving files into correct libdir failed"
		rm -rf "${D}"/usr/lib
		for dir in "${D}"/usr/"$(get_libdir)"/pkgconfig "${D}"/usr/share/pkgconfig
		do

			if [[ -d "${dir}" && "$(find "${dir}" -name '*.pc')" != "" ]]
			then
				pushd "${dir}" &> /dev/null
				sed  -i -r -e 's:/(lib)([^a-zA-Z0-9]|$):/'"$(get_libdir)"'\2:g' \
					*.pc \
					|| die "Sedding some sense into pkgconfig files failed."
				popd "${dir}" &> /dev/null
			fi
		done
		if [[ -d "${D}/usr/bin" ]]
		then
			for exe in "${D}/usr/bin"/*
			do
				if [[ "$(file "${exe}")" == *"shell script text"* ]]
				then
					sed -r -i -e ":/lib(/|$): s:/lib(/|$):/$(get_libdir)\1:" \
						"${exe}" || die "Sedding some sense into ${exe} failed"
				fi
			done
		fi

	fi
}
