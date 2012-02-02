# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/sgml-catalog.eclass,v 1.14 2005/09/08 17:37:32 leonardop Exp $
#
# Author Matthew Turk <satai@gentoo.org>

inherit base

DEPEND=">=app-text/sgml-common-0.6.3-r2"


# List of catalogs to install
SGML_TOINSTALL=""


sgml-catalog_cat_include() {
	debug-print function $FUNCNAME $*
	SGML_TOINSTALL="${SGML_TOINSTALL} ${1}:${2}"
}

sgml-catalog_cat_doinstall() {
	debug-print function $FUNCNAME $*
	/usr/bin/install-catalog --add $1 $2 &>/dev/null
}

sgml-catalog_cat_doremove() {
	debug-print function $FUNCNAME $*
	/usr/bin/install-catalog --remove $1 $2 &>/dev/null
}

sgml-catalog_pkg_postinst() {
	debug-print function $FUNCNAME $*

	for entry in ${SGML_TOINSTALL}; do
		arg1=`echo ${entry} | cut -f1 -d\:`
		arg2=`echo ${entry} | cut -f2 -d\:`
		if [ ! -e ${arg2} ]
		then
			ewarn "${arg2} doesn't appear to exist, although it ought to!"
			continue
		fi
		einfo "Now adding ${arg2} to ${arg1} and /etc/sgml/catalog"
		sgml-catalog_cat_doinstall ${arg1} ${arg2}
	done
	sgml-catalog_cleanup
}

sgml-catalog_pkg_prerm() {
	sgml-catalog_cleanup
}

sgml-catalog_pkg_postrm() {
	debug-print function $FUNCNAME $*

	for entry in ${SGML_TOINSTALL}; do
		arg1=`echo ${entry} | cut -f1 -d\:`
		arg2=`echo ${entry} | cut -f2 -d\:`
		if [ -e ${arg2} ]
		then
			ewarn "${arg2} still exists!  Not removing from ${arg1}"
			ewarn "This is normal behavior for an upgrade ..."
			continue
		fi
		einfo "Now removing $arg1 from $arg2 and /etc/sgml/catalog"
		sgml-catalog_cat_doremove ${arg1} ${arg2}
	done
}

sgml-catalog_cleanup() {
	if [ -e /usr/bin/gensgmlenv ]
	then
		einfo Regenerating SGML environment variables ...
		gensgmlenv
		grep -v export /etc/sgml/sgml.env > /etc/env.d/93sgmltools-lite
	fi
}

sgml-catalog_src_compile() {
	return
}

EXPORT_FUNCTIONS pkg_postrm pkg_postinst src_compile pkg_prerm
