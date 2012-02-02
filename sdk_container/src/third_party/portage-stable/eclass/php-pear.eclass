# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/php-pear.eclass,v 1.15 2008/01/06 19:30:24 swegener Exp $
#
# Author: Tal Peer <coredumb@gentoo.org>
#
# The php-pear eclass provides means for easy installation of PEAR
# packages, see http://pear.php.net

# Note that this eclass doesn't handle PEAR packages' dependencies on
# purpose, please use (R)DEPEND to define them.

# DEPRECATED!!!
# STOP USING THIS ECLASS, use php-pear-r1.eclass instead!

inherit php-pear-r1

deprecation_warning() {
	eerror "Please upgrade ${PF} to use php-pear-r1.eclass!"
}

php-pear_src_install () {
	deprecation_warning
	php-pear-r1_src_install
}
