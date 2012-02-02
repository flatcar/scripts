# Copyright 2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/qt3.eclass,v 1.41 2009/05/17 15:17:03 hwoarang Exp $

# @ECLASS: qt3.eclass
# @MAINTAINER:
# Qt team <qt@gentoo.org>
# @BLURB: Eclass for Qt3 packages
# @DESCRIPTION:
# This eclass contains various functions that may be useful
# when dealing with packages using Qt3 libraries.

inherit toolchain-funcs versionator eutils

QTPKG="x11-libs/qt-"
QT3MAJORVERSIONS="3.3 3.2 3.1 3.0"
QT3VERSIONS="3.3.8b-r1 3.3.8b 3.3.8-r4 3.3.8-r3 3.3.8-r2 3.3.8-r1 3.3.8 3.3.6-r5 3.3.6-r4 3.3.6-r3 3.3.6-r2 3.3.6-r1 3.3.6 3.3.5-r1 3.3.5 3.3.4-r9 3.3.4-r8 3.3.4-r7 3.3.4-r6 3.3.4-r5 3.3.4-r4 3.3.4-r3 3.3.4-r2 3.3.4-r1 3.3.4 3.3.3-r3 3.3.3-r2 3.3.3-r1 3.3.3 3.3.2 3.3.1-r2 3.3.1-r1 3.3.1 3.3.0-r1 3.3.0 3.2.3-r1 3.2.3 3.2.2-r1 3.2.2 3.2.1-r2 3.2.1-r1 3.2.1 3.2.0 3.1.2-r4 3.1.2-r3 3.1.2-r2 3.1.2-r1 3.1.2 3.1.1-r2 3.1.1-r1 3.1.1 3.1.0-r3 3.1.0-r2 3.1.0-r1 3.1.0"

if [[ -z "${QTDIR}" ]]; then
	export QTDIR="/usr/qt/3"
fi

addwrite "${QTDIR}/etc/settings"
addpredict "${QTDIR}/etc/settings"

# @FUNCTION: qt_min_version
# @USAGE: [minimum version]
# @DESCRIPTION:
# This function is deprecated. Use slot dependencies instead.
qt_min_version() {
	local list=$(qt_min_version_list "$@")
	ewarn "${CATEGORY}/${PF}: qt_min_version() is deprecated. Use slot dependencies instead."
	if [[ ${list%% *} == "${list}" ]]; then
		echo "${list}"
	else
		echo "|| ( ${list} )"
	fi
}

qt_min_version_list() {
	local MINVER="$1"
	local VERSIONS=""

	case "${MINVER}" in
		3|3.0|3.0.0) VERSIONS="=${QTPKG}3*";;
		3.1|3.1.0|3.2|3.2.0|3.3|3.3.0)
			for x in ${QT3MAJORVERSIONS}; do
				if $(version_is_at_least "${MINVER}" "${x}"); then
					VERSIONS="${VERSIONS} =${QTPKG}${x}*"
				fi
			done
			;;
		3*)
			for x in ${QT3VERSIONS}; do
				if $(version_is_at_least "${MINVER}" "${x}"); then
					VERSIONS="${VERSIONS} =${QTPKG}${x}"
				fi
			done
			;;
		*) VERSIONS="=${QTPKG}3*";;
	esac

	echo ${VERSIONS}
}

# @FUNCTION: eqmake3
# @USAGE: [.pro file] [additional parameters to qmake]
# @MAINTAINER:
# Przemyslaw Maciag <troll@gentoo.org>
# Davide Pesavento <davidepesa@gmail.com>
# @DESCRIPTION:
# Runs qmake on the specified .pro file (defaults to
# ${PN}.pro if eqmake3 was called with no argument).
# Additional parameters are passed unmodified to qmake.
eqmake3() {
	local LOGFILE="${T}/qmake-$$.out"
	local projprofile="${1}"
	[[ -z ${projprofile} ]] && projprofile="${PN}.pro"
	shift 1

	ebegin "Processing qmake ${projprofile}"

	# file exists?
	if [[ ! -f ${projprofile} ]]; then
		echo
		eerror "Project .pro file \"${projprofile}\" does not exist"
		eerror "qmake cannot handle non-existing .pro files"
		echo
		eerror "This shouldn't happen - please send a bug report to bugs.gentoo.org"
		echo
		die "Project file not found in ${PN} sources"
	fi

	echo >> ${LOGFILE}
	echo "******  qmake ${projprofile}  ******" >> ${LOGFILE}
	echo >> ${LOGFILE}

	# some standard config options
	local configoptplus="CONFIG += no_fixpath"
	local configoptminus="CONFIG -="
	if has debug ${IUSE} && use debug; then
		configoptplus="${configoptplus} debug"
		configoptminus="${configoptminus} release"
	else
		configoptplus="${configoptplus} release"
		configoptminus="${configoptminus} debug"
	fi

	${QTDIR}/bin/qmake ${projprofile} \
		QTDIR=${QTDIR} \
		QMAKE=${QTDIR}/bin/qmake \
		QMAKE_CC=$(tc-getCC) \
		QMAKE_CXX=$(tc-getCXX) \
		QMAKE_LINK=$(tc-getCXX) \
		QMAKE_CFLAGS_RELEASE="${CFLAGS}" \
		QMAKE_CFLAGS_DEBUG="${CFLAGS}" \
		QMAKE_CXXFLAGS_RELEASE="${CXXFLAGS}" \
		QMAKE_CXXFLAGS_DEBUG="${CXXFLAGS}" \
		QMAKE_LFLAGS_RELEASE="${LDFLAGS}" \
		QMAKE_LFLAGS_DEBUG="${LDFLAGS}" \
		"${configoptminus}" \
		"${configoptplus}" \
		QMAKE_RPATH= \
		QMAKE_STRIP= \
		${@} >> ${LOGFILE} 2>&1

	local result=$?
	eend ${result}

	# was qmake successful?
	if [[ ${result} -ne 0 ]]; then
		echo
		eerror "Running qmake on \"${projprofile}\" has failed"
		echo
		eerror "This shouldn't happen - please send a bug report to bugs.gentoo.org"
		echo
		die "qmake failed on ${projprofile}"
	fi

	return ${result}
}
