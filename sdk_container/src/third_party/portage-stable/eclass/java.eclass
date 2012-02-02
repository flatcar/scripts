# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/java.eclass,v 1.33 2009/11/30 04:19:36 abcd Exp $

# @DEAD
# To be removed on 2011/11/30.
ewarn "Please fix your package (${CATEGORY}/${PF}) to not use ${ECLASS}.eclass"

EXPORT_FUNCTIONS pkg_prerm

java_pkg_prerm() {
	if java-config -J | grep -q ${P} ; then
		ewarn "It appears you are removing your default system VM!"
		ewarn "Please run java-config -L then java-config -S to set a new system VM!"
	fi
}
