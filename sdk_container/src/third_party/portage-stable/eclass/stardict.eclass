# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/stardict.eclass,v 1.16 2010/02/03 13:16:39 pva Exp $

# Author : Alastair Tse <liquidx@gentoo.org>
#
# Convienence class to do stardict dictionary installations.
#
# Usage:
#   - Variables to set :
#      * FROM_LANG     -  From this language
#      * TO_LANG       -  To this language
#      * DICT_PREFIX   -  SRC_URI prefix, like "dictd_www.mova.org_"
#	   * DICT_SUFFIX   -  SRC_URI after the prefix.

RESTRICT="strip"

[ -z "${DICT_SUFFIX}" ] && DICT_SUFFIX=${PN#stardict-[[:lower:]]*-}
[ -z "${DICT_P}" ] && DICT_P=stardict-${DICT_PREFIX}${DICT_SUFFIX}-${PV}

if [ -n "${FROM_LANG}" -a -n "${TO_LANG}" ]; then
	DESCRIPTION="Stardict Dictionary ${FROM_LANG} to ${TO_LANG}"
elif [ -z "${DESCRIPTION}" ]; then
	DESCRIPTION="Another Stardict Dictionary"
fi

HOMEPAGE="http://stardict.sourceforge.net/"
SRC_URI="mirror://sourceforge/stardict/${DICT_P}.tar.bz2"

IUSE="gzip"
SLOT="0"
LICENSE="GPL-2"

DEPEND=">=app-text/stardict-2.4.2
		gzip? ( app-arch/gzip
				app-text/dictd )"

S=${WORKDIR}/${DICT_P}

stardict_src_compile() {
	if use gzip; then
		for file in *.idx; do
			[[ -f $file ]] && gzip ${file}
		done
		for file in *.dict; do
			[[ -f $file ]] && dictzip ${file}
		done
	fi
}

stardict_src_install() {
	insinto /usr/share/stardict/dic
	doins *.dict.dz*
	doins *.idx*
	doins *.ifo
}

EXPORT_FUNCTIONS src_compile src_install
