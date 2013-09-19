# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/leechcraft.eclass,v 1.10 2013/05/08 10:25:48 pinkbyte Exp $
#
# @ECLASS: leechcraft.eclass
# @MAINTAINER:
# leechcraft@gentoo.org
# @AUTHOR:
# 0xd34df00d@gmail.com
# NightNord@niifaq.ru
# @BLURB: Common functions and setup utilities for the LeechCraft app
# @DESCRIPTION:
# The leechcraft eclass contains a common set of functions and steps
# needed to build LeechCraft core or its plugins.
#
# Though this eclass seems to be small at the moment, it seems like a
# good idea to make all plugins inherit from it, since all plugins
# have mostly the same configuring/build process.
#
# Thanks for original eclass to Andrian Nord <NightNord@niifaq.ru>.
#
# Only EAPI >1 supported

case ${EAPI:-0} in
	4|5) ;;
	0|1|2|3) die "EAPI not supported, bug ebuild mantainer" ;;
	*) die "Unknown EAPI, bug eclass maintainers" ;;
esac

inherit cmake-utils toolchain-funcs versionator

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="git://github.com/0xd34df00d/leechcraft.git"
	EGIT_PROJECT="leechcraft"

	inherit git-2
else
	DEPEND="app-arch/xz-utils"
	SRC_URI="mirror://sourceforge/leechcraft/leechcraft-${PV}.tar.xz"
	S="${WORKDIR}/leechcraft-${PV}"
fi

HOMEPAGE="http://leechcraft.org/"
if version_is_at_least 0.5.95; then
	LICENSE="Boost-1.0"
else
	LICENSE="GPL-3"
fi

# @ECLASS-VARIABLE: LEECHCRAFT_PLUGIN_CATEGORY
# @DEFAULT_UNSET
# @DESCRIPTION:
# Set this to the category of the plugin, if any.
: ${LEECHCRAFT_PLUGIN_CATEGORY:=}

if [[ "${LEECHCRAFT_PLUGIN_CATEGORY}" ]]; then
	CMAKE_USE_DIR="${S}"/src/plugins/${LEECHCRAFT_PLUGIN_CATEGORY}/${PN#lc-}
elif [[ ${PN} != lc-core ]]; then
	CMAKE_USE_DIR="${S}"/src/plugins/${PN#lc-}
else
	CMAKE_USE_DIR="${S}"/src
fi

EXPORT_FUNCTIONS "pkg_pretend"

# @FUNCTION: leechcraft_pkg_pretend
# @DESCRIPTION:
# Determine active compiler version and refuse to build
# if it is not satisfied at least to minimal version,
# supported by upstream developers
leechcraft_pkg_pretend() {
	debug-print-function ${FUNCNAME} "$@"

	if version_is_at_least 0.5.85; then
		# 0.5.85 and later requires at least gcc 4.6
		if [[ ${MERGE_TYPE} != binary ]]; then
			[[ $(gcc-major-version) -lt 4 ]] || \
					( [[ $(gcc-major-version) -eq 4 && $(gcc-minor-version) -lt 6 ]] ) \
				&& die "Sorry, but gcc 4.6 or higher is required."
		fi
	fi
}
