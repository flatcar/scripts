# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/eclipse-ext.eclass,v 1.13 2006/04/17 03:47:44 nichoj Exp $

# Original Author: Karl Trygve Kalleberg <karltk@gentoo.org>
# Maintainers:
#		Development Tools Team <dev-tools@gentoo.org>
#		Java Team <java@gentoo.org>

inherit eutils multilib


# Must be listed in oldest->newest order!
known_eclipse_slots="2 3 3.1"

# These should not be reinitialized if previously set
# (check allows require-slot in pkg_setup)

[ -z "${eclipse_ext_type}" ] && \
	eclipse_ext_type="source"

[ -z "${eclipse_ext_slot}" ] && \
	eclipse_ext_slot="0"

[ -z "${eclipse_ext_basedir}" ] && \
	eclipse_ext_basedir="/usr/$(get_libdir)/eclipse-extensions-${eclipse_ext_slot}/eclipse"

[ -z "${eclipse_ext_platformdir}" ] && \
	eclipse_ext_platformdir="/usr/$(get_libdir)/eclipse-${eclipse_ext_slot}"

# ---------------------------------------------------------------------------
# @private _find-optimum-slot
#
# Look for a given SLOT. If not found return the least highest SLOT
# available.
#
# @param $1 - SLOT of Eclipse SDK that is most desired
# @return 0 - all is well, non-zero otherwise
# ---------------------------------------------------------------------------
function _find-optimum-slot {
	local found=false

	for x in ${known_eclipse_slots} ; do
		if [ "$1" == "$x" ] ; then
			found=true
		fi
		if [ "${found}" == "true" ] && [ -d /usr/$(get_libdir)/eclipse-${x} ] ; then
			echo $x
			return 0
		fi
	done
	echo ""
	return 1
}

# ---------------------------------------------------------------------------
# @public require-slot
#
# Ensure that an Eclipse SDK is actually available for the given slot;
# sets internal state to install for selected slot.
#
# @param $1 - SLOT of Eclipse SDK that required for this ebuild
# alternatively
# @return 0 - all is well, non-zero otherwise
# ---------------------------------------------------------------------------
function eclipse-ext_require-slot {

	local slot=$(_find-optimum-slot $1)

	if [ -z "${slot}" ] ; then
		eerror "Cannot find any Eclipse SDK supporting slot $1"
		return 1
	fi

	if [ "${slot}" != "$1" ] ; then
		ewarn "Slot $1 could not be satisfied, installing for ${slot} instead"
	fi

	eclipse_ext_slot=${slot}
	eclipse_ext_basedir="/usr/$(get_libdir)/eclipse-extensions-${eclipse_ext_slot}/eclipse"
	eclipse_ext_platformdir="/usr/$(get_libdir)/eclipse-${eclipse_ext_slot}"

	return 0
}

# ---------------------------------------------------------------------------
# @public create-plugin-layout
#
# Create directory infrastructure for binary-only plugins so that the installed
# Eclipse SDK will see them. Sets internal state for installing as source or
# binary.
#
# @param $1 - type of ebuild, "source" or "binary"
# @return   - nothing
# ---------------------------------------------------------------------------
function eclipse-ext_create-ext-layout {
	local type=$1
	if [ "${type}" == "binary" ] ; then
		eclipse_ext_basedir="/opt/eclipse-extensions-${eclipse_ext_slot}/eclipse"
		dodir ${eclipse_ext_basedir}/{features,plugins}
		touch ${D}/${eclipse_ext_basedir}/.eclipseextension
	else
		eclipse_ext_basedir="/usr/$(get_libdir)/eclipse-extensions-${eclipse_ext_slot}/eclipse"
		dodir ${eclipse_ext_basedir}/{features,plugins}
		touch ${D}/${eclipse_ext_basedir}/.eclipseextension
	fi
}

# ---------------------------------------------------------------------------
# @public install-features
#
# Installs one or multiple features into the plugin directory for the required
# Eclipse SDK.
#
# Note: You must call require-slot prior to calling install-features. If your
# ebuild is for a binary-only plugin, you must also call create-plugin-layout
# prior to calling install-features.
#
# @param $* - feature directories
# @return 0 - if all is well
#         1 - if require-slot was not called
# ---------------------------------------------------------------------------
function eclipse-ext_install-features {
	if [ ${eclipse_ext_slot} == 0 ] ; then
		eerror "You must call require-slot prior to calling ${FUNCNAME}!"
		return 1
	fi

	for x in $* ; do
		if [ -d "$x" ] && [ -f $x/feature.xml ] ; then
			cp -a $x ${D}/${eclipse_ext_basedir}/features
		else
			eerror "$x not a feature directory!"
		fi
	done
}

# ---------------------------------------------------------------------------
# @public install-plugins
#
# Installs one or multiple plugins into the plugin directory for the required
# Eclipse SDK.
#
# Note: You must call require-slot prior to calling install-features. If your
# ebuild is for a binary-only plugin, you must also call create-plugin-layout
# prior to calling install-features.
#
# @param $* - plugin directories
# @return   - nothing
# ---------------------------------------------------------------------------

function eclipse-ext_install-plugins {
	if [ ${eclipse_ext_slot} == 0 ] ; then
		eerror "You must call require-slot prior to calling ${FUNCNAME}!"
		return 1
	fi

	for x in $* ; do
		if [ -d "$x" ] && ( [ -f "$x/plugin.xml" ] || [ -f "$x/fragment.xml" ] ) ; then
			cp -a $x ${D}/${eclipse_ext_basedir}/plugins
		else
			eerror "$x not a plugin directory!"
		fi
	done
}

# TODO really should have a page hosted on gentoo's infra
function eclipse-ext_pkg_postinst() {
	einfo "For tips, tricks and general info on running Eclipse on Gentoo, go to:"
	einfo "http://gentoo-wiki.com/Eclipse"
}

# ---------------------------------------------------------------------------
# @public get-classpath
#
# Tries to parse out a classpath string from a build.properties file. Is very
# stupid: Assumes it's a one-liner on the form classpath = comma:separated:
#
# @param $1 - name of the file (typically build.properties)
# @param $2 - name of the one-liner env var (default 'classpath')
# @return - echo of space-separated classpath entries.
# ---------------------------------------------------------------------------

eclipse-ext_get-classpath() {
	local file=$1
	local envvar="classpath"

	if [ "$1" == "build.properties" ] ; then
		if [ ! -z "$2" ] ; then
			envvar="$2"
		fi
	fi

	echo "$(cat ${FILESDIR}/build.properties-${PV} | sed "s/.*=//" | tr ';' ' ')"
}

_path-dissecter() {
	echo $1 | sed -r "s/.*\/([^/]+)_([0-9.]+)\/(.*)/\\${2}/"
}

_get-plugin-name() {
	_path-dissecter $1 1
}

_get-plugin-version() {
	_path-dissecter $1 2
}

_get-plugin-content() {
	_path-dissecter $1 3
}

# ---------------------------------------------------------------------------
# @public resolve-jars
#
# Takes a space-separated list of plugin_version/subdirs/file.jar entries and
# tries to resolve the version for the plugin against the chosen eclipse version
# (set by require-slot).
#
# Note: You must call require-slot prior to calling resolve-jars.
#
# @param $1 - string with space-separated plugin/jarfile
# @return - echo of :-separated resolved files
# ---------------------------------------------------------------------------
eclipse-ext_resolve-jars() {
	local resolved=""

	for x in $1 ; do
		local jarfile=$(_get-plugin-content $x)
		local name="$(_get-plugin-name $x)"
		local x=$(echo ${eclipse_ext_platformdir}/plugins/${name}_*/${jarfile})
		if [ -f ${x} ] ; then
			resolved="${resolved}:$x"
		else
			:
			#echo "Warning: did not find ${name}"
		fi
	done
	echo ${resolved}
}

EXPORT_FUNCTIONS pkg_postinst
