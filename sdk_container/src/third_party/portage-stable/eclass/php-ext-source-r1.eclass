# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/php-ext-source-r1.eclass,v 1.19 2008/05/09 13:02:04 hoffie Exp $
#
# Author: Tal Peer <coredumb@gentoo.org>
# Author: Stuart Herbert <stuart@gentoo.org>
# Author: Luca Longinotti <chtekk@gentoo.org>
# Author: Jakub Moc <jakub@gentoo.org> (documentation)

# @ECLASS: php-ext-src-r1.eclass
# @MAINTAINER:
# Gentoo PHP team <php-bugs@gentoo.org>
# @BLURB: A unified interface for compiling and installing standalone PHP extensions from source code.
# @DESCRIPTION:
# This eclass provides a unified interface for compiling and installing standalone
# PHP extensions (modules) from source code.


WANT_AUTOCONF="latest"
WANT_AUTOMAKE="latest"

inherit php-ext-base-r1 flag-o-matic autotools depend.php

EXPORT_FUNCTIONS src_unpack src_compile src_install

# @ECLASS-VARIABLE: PHP_EXT_NAME
# @DESCRIPTION:
# The extension name. This must be set, otherwise the eclass dies.
# Only automagically set by php-ext-pecl-r1.eclass, so unless your ebuild
# inherits that eclass, you must set this manually before inherit.
[[ -z "${PHP_EXT_NAME}" ]] && die "No module name specified for the php-ext-source-r1 eclass"

DEPEND=">=sys-devel/m4-1.4.3
		>=sys-devel/libtool-1.5.18"
RDEPEND=""


# @FUNCTION: php-ext-source-r1_src_unpack
# @DESCRIPTION:
# runs standard src_unpack + _phpize
#
# @VARIABLE: PHP_EXT_SKIP_PHPIZE
# @DESCRIPTION:
# phpize will be run by default for all ebuilds that use
# php-ext-source-r1_src_unpack
# Set PHP_EXT_SKIP_PHPIZE="yes" in your ebuild if you do not want to run phpize.
php-ext-source-r1_src_unpack() {
	unpack ${A}
	cd "${S}"
	if [[ "${PHP_EXT_SKIP_PHPIZE}" != 'yes' ]] ; then
		php-ext-source-r1_phpize
	fi
}

# @FUNCTION php-ext-source-r1_phpize
# @DESCRIPTION:
# Runs phpize and autotools in addition to the standard src_unpack
php-ext-source-r1_phpize() {
	has_php
	# Create configure out of config.m4
	${PHPIZE}
	# force run of libtoolize and regeneration of related autotools
	# files (bug 220519)
	rm aclocal.m4
	eautoreconf
}

# @FUNCTION: php-ext-source-r1_src_compile
# @DESCRIPTION:
# Takes care of standard compile for PHP extensions (modules).

# @VARIABLE: my_conf
# @DESCRIPTION:
# Set this in the ebuild to pass configure options to econf.
php-ext-source-r1_src_compile() {
	# Pull in the PHP settings
	has_php
	addpredict /usr/share/snmp/mibs/.index
	addpredict /session_mm_cli0.sem

	# Set the correct config options
	my_conf="--prefix=${PHPPREFIX} --with-php-config=${PHPCONFIG} ${my_conf}"

	# Concurrent PHP Apache2 modules support
	if has_concurrentmodphp ; then
		append-ldflags "-Wl,--version-script=${ROOT}/var/lib/php-pkg/${PHP_PKG}/php${PHP_VERSION}-ldvs"
	fi

	# First compile run: the default one
	econf ${my_conf} || die "Unable to configure code to compile"
	emake || die "Unable to make code"
	mv -f "modules/${PHP_EXT_NAME}.so" "${WORKDIR}/${PHP_EXT_NAME}-default.so" || die "Unable to move extension"

	# Concurrent PHP Apache2 modules support
	if has_concurrentmodphp ; then
		# First let's clean up
		make distclean || die "Unable to clean build environment"

		# Second compile run: the versioned one
		econf ${my_conf} || die "Unable to configure versioned code to compile"
		sed -e "s|-Wl,--version-script=${ROOT}/var/lib/php-pkg/${PHP_PKG}/php${PHP_VERSION}-ldvs|-Wl,--version-script=${ROOT}/var/lib/php-pkg/${PHP_PKG}/php${PHP_VERSION}-ldvs -Wl,--allow-shlib-undefined -L/usr/$(get_libdir)/apache2/modules/ -lphp${PHP_VERSION}|g" -i Makefile
		append-ldflags "-Wl,--allow-shlib-undefined -L/usr/$(get_libdir)/apache2/modules/ -lphp${PHP_VERSION}"
		emake || die "Unable to make versioned code"
		mv -f "modules/${PHP_EXT_NAME}.so" "${WORKDIR}/${PHP_EXT_NAME}-versioned.so" || die "Unable to move versioned extension"
	fi
}

# @FUNCTION: php-ext-source-r1_src_install
# @DESCRIPTION:
# Takes care of standard install for PHP extensions (modules).

# @VARIABLE: DOCS
# @DESCRIPTION:
# Set in ebuild if you wish to install additional, package-specific documentation.
php-ext-source-r1_src_install() {
	# Pull in the PHP settings
	has_php
	addpredict /usr/share/snmp/mibs/.index

	# Let's put the default module away
	insinto "${EXT_DIR}"
	newins "${WORKDIR}/${PHP_EXT_NAME}-default.so" "${PHP_EXT_NAME}.so" || die "Unable to install extension"

	# And now the versioned one, if it exists
	if has_concurrentmodphp ; then
		insinto "${EXT_DIR}-versioned"
		newins "${WORKDIR}/${PHP_EXT_NAME}-versioned.so" "${PHP_EXT_NAME}.so" || die "Unable to install extension"
	fi

	for doc in ${DOCS} ; do
		[[ -s ${doc} ]] && dodoc-php ${doc}
	done

	php-ext-base-r1_src_install
}
