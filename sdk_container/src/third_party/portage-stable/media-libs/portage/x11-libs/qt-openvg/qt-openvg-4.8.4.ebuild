# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/qt-openvg/qt-openvg-4.8.4.ebuild,v 1.4 2012/12/25 09:54:53 ago Exp $

EAPI=4

inherit qt4-build

DESCRIPTION="The OpenVG module for the Qt toolkit"
SLOT="4"
if [[ ${QT4_BUILD_TYPE} == live ]]; then
	KEYWORDS=""
else
	KEYWORDS="amd64 ~arm ~ia64 ppc ~ppc64 x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris ~x86-solaris"
fi
IUSE="qt3support"

DEPEND="
	media-libs/mesa[egl,openvg]
	~x11-libs/qt-core-${PV}[aqua=,debug=,qt3support=]
	~x11-libs/qt-gui-${PV}[aqua=,debug=,egl,qt3support=]
"
RDEPEND="${DEPEND}"

pkg_setup() {
	QT4_TARGET_DIRECTORIES="
		src/openvg
		src/plugins/graphicssystems/openvg"

	QT4_EXTRACT_DIRECTORIES="
		include/QtCore
		include/QtGui
		include/QtOpenVG
		src/corelib
		src/gui
		src/openvg
		src/plugins
		src/3rdparty"

	QCONFIG_ADD="openvg"
	QCONFIG_DEFINE="QT_OPENVG"

	qt4-build_pkg_setup
}

src_configure() {
	gltype="desktop"

	myconf+="
		-openvg -egl
		$(qt_use qt3support)"

	qt4-build_src_configure
}

src_install() {
	qt4-build_src_install

	# touch the available graphics systems
	dodir /usr/share/qt4/graphicssystems
	echo "experimental" > "${ED}"/usr/share/qt4/graphicssystems/openvg || die
}
