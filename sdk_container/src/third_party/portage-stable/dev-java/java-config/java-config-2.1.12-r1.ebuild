# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-java/java-config/java-config-2.1.12-r1.ebuild,v 1.8 2013/04/11 15:49:11 mgorny Exp $

EAPI="5"

# jython depends on java-config, so don't add it or things will breake.
PYTHON_COMPAT=( python{2_6,2_7,3_1,3_2,3_3} )

inherit distutils-r1 eutils fdo-mime gnome2-utils

DESCRIPTION="Java environment configuration tool"
HOMEPAGE="http://www.gentoo.org/proj/en/java/"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="2"
KEYWORDS="amd64 ~arm ~ia64 ppc ppc64 x86 ~amd64-fbsd ~x86-fbsd"
IUSE=""

DEPEND=""
RDEPEND=">=dev-java/java-config-wrapper-0.15
	!sys-apps/baselayout-java
	!app-admin/eselect-java"
# https://bugs.gentoo.org/show_bug.cgi?id=315229
PDEPEND=">=virtual/jre-1.5"
# Tests fail when java-config isn't already installed.
RESTRICT="test"

python_test() {
	"${PYTHON}" src/run-test-suite.py || die
	"${PYTHON}" src/run-test-suite2.py || die
}

python_install_all() {
	distutils-r1_python_install_all

	insinto /usr/share/java-config-2/config/
	newins config/jdk-defaults-${ARCH}.conf jdk-defaults.conf
}

pkg_postrm() {
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}

pkg_postinst() {
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}
