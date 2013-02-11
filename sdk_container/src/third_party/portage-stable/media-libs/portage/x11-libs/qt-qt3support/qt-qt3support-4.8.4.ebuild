# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/qt-qt3support/qt-qt3support-4.8.4.ebuild,v 1.10 2012/12/29 08:47:31 ago Exp $

EAPI=4

inherit qt4-build

DESCRIPTION="The Qt3 support module for the Qt toolkit"
SLOT="4"
if [[ ${QT4_BUILD_TYPE} == live ]]; then
	KEYWORDS=""
else
	KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x64-solaris ~x86-solaris"
fi
IUSE="+accessibility"

DEPEND="
	~x11-libs/qt-core-${PV}[aqua=,debug=,qt3support]
	~x11-libs/qt-gui-${PV}[accessibility=,aqua=,debug=,qt3support]
	~x11-libs/qt-sql-${PV}[aqua=,debug=,qt3support]
"
RDEPEND="${DEPEND}"

pkg_setup() {
	QT4_TARGET_DIRECTORIES="
		src/qt3support
		src/tools/uic3
		tools/designer/src/plugins/widgets
		tools/porting"

	QT4_EXTRACT_DIRECTORIES="
		src
		include
		tools"

	qt4-build_pkg_setup
}

src_configure() {
	myconf+="
		-qt3support
		$(qt_use accessibility)"

	qt4-build_src_configure
}
