# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/php-pear-lib-r1.eclass,v 1.15 2009/01/12 22:48:06 maekke Exp $
#
# Author: Luca Longinotti <chtekk@gentoo.org>

# @ECLASS: php-pear-lib-r1.eclass
# @MAINTAINER:
# Gentoo PHP team <php-bugs@gentoo.org>
# @BLURB: Provides means for an easy installation of PEAR-based libraries.
# @DESCRIPTION:
# This class provides means for an easy installation of PEAR-based libraries,
# such as Creole, Jargon, Phing etc., while retaining the functionality to put
# the libraries into version-dependant directories.

inherit depend.php multilib

EXPORT_FUNCTIONS src_install

DEPEND="dev-lang/php >=dev-php/PEAR-PEAR-1.6.1"
RDEPEND="${DEPEND}"

# @FUNCTION: php-pear-lib-r1_src_install
# @DESCRIPTION:
# Takes care of standard install for PEAR-based libraries.
php-pear-lib-r1_src_install() {
	has_php

	# SNMP support
	addpredict /usr/share/snmp/mibs/.index
	addpredict /var/lib/net-snmp/
	addpredict /session_mm_cli0.sem

	case "${CATEGORY}" in
		dev-php)
			if has_version '=dev-lang/php-5*' ; then
				PHP_BIN="/usr/$(get_libdir)/php5/bin/php"
			else
				PHP_BIN="/usr/$(get_libdir)/php4/bin/php"
			fi ;;
		dev-php4) PHP_BIN="/usr/$(get_libdir)/php4/bin/php" ;;
		dev-php5) PHP_BIN="/usr/$(get_libdir)/php5/bin/php" ;;
		*) die "Version of PHP required by packages in category ${CATEGORY} unknown"
	esac

	cd "${S}"

	if [[ -f "${WORKDIR}"/package2.xml ]] ; then
		mv -f "${WORKDIR}/package2.xml" "${S}"
		if has_version '>=dev-php/PEAR-PEAR-1.7.0' ; then
			local WWW_DIR="/usr/share/webapps/${PN}/${PVR}/htdocs"
			pear -d php_bin="${PHP_BIN}" -d www_dir="${WWW_DIR}" \
				install --force --loose --nodeps --offline --packagingroot="${D}" \
				"${S}/package2.xml" || die "Unable to install PEAR package"
		else
			pear -d php_bin="${PHP_BIN}" install --force --loose --nodeps --offline --packagingroot="${D}" \
				"${S}/package2.xml" || die "Unable to install PEAR package"
		fi
	else
		mv -f "${WORKDIR}/package.xml" "${S}"
		if has_version '>=dev-php/PEAR-PEAR-1.7.0' ; then
			local WWW_DIR="/usr/share/webapps/${PN}/${PVR}/htdocs"
			pear -d php_bin="${PHP_BIN}" -d www_dir="${WWW_DIR}" \
				install --force --loose --nodeps --offline --packagingroot="${D}" \
					"${S}/package.xml" || die "Unable to install PEAR package"
		else
			pear -d php_bin="${PHP_BIN}" install --force --loose --nodeps --offline --packagingroot="${D}" \
				"${S}/package.xml" || die "Unable to install PEAR package"
		fi
	fi

	rm -Rf "${D}/usr/share/php/.channels" \
	"${D}/usr/share/php/.depdblock" \
	"${D}/usr/share/php/.depdb" \
	"${D}/usr/share/php/.filemap" \
	"${D}/usr/share/php/.lock" \
	"${D}/usr/share/php/.registry"

	# install to the correct phpX folder, if not specified
	# /usr/share/php will be kept, also sedding to substitute
	# the path, many files can specify it wrongly
	if [[ -n "${PHP_SHARED_CAT}" ]] && [[ "${PHP_SHARED_CAT}" != "php" ]] ; then
		mv -f "${D}/usr/share/php" "${D}/usr/share/${PHP_SHARED_CAT}" || die "Unable to move files"
		find "${D}/" -type f -exec sed -e "s|/usr/share/php|/usr/share/${PHP_SHARED_CAT}|g" -i {} \; \
			|| die "Unable to change PHP path"
		einfo
		einfo "Installing to /usr/share/${PHP_SHARED_CAT} ..."
		einfo
	else
		einfo
		einfo "Installing to /usr/share/php ..."
		einfo
	fi
}
