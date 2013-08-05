# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-java/java-config/java-config-2.1.11.ebuild,v 1.13 2013/04/06 10:21:50 caster Exp $

EAPI="2"
PYTHON_DEPEND="*:2.6"
SUPPORT_PYTHON_ABIS="1"

inherit fdo-mime gnome2-utils distutils eutils

DESCRIPTION="Java environment configuration tool"
HOMEPAGE="http://www.gentoo.org/proj/en/java/"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="2"
KEYWORDS="amd64 ppc ppc64 ~sparc x86 ~x86-fbsd"
IUSE=""

DEPEND=""
RDEPEND=">=dev-java/java-config-wrapper-0.15
	!sys-apps/baselayout-java
	!app-admin/eselect-java"
# Tests fail when java-config isn't already installed.
RESTRICT="test"
RESTRICT_PYTHON_ABIS="2.4 2.5 *-jython"

PYTHON_MODNAME="java_config_2"

src_test() {
	testing() {
		PYTHONPATH="build-${PYTHON_ABI}/lib" "$(PYTHON)" src/run-test-suite.py
	}
	python_execute_function testing
}

src_install() {
	distutils_src_install

	insinto /usr/share/java-config-2/config/
	newins config/jdk-defaults-${ARCH}.conf jdk-defaults.conf || die "arch config not found"
}

pkg_postrm() {
	distutils_pkg_postrm
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}

pkg_postinst() {
	distutils_pkg_postinst
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}
