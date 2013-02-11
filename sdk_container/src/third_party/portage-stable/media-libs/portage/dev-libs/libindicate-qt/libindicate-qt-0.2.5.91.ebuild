# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libindicate-qt/libindicate-qt-0.2.5.91.ebuild,v 1.4 2012/08/16 14:55:32 kensington Exp $

EAPI=4
inherit eutils virtualx cmake-utils

_UBUNTU_REVISION=5

DESCRIPTION="Qt wrapper for libindicate library"
HOMEPAGE="https://launchpad.net/libindicate-qt/"
SRC_URI="mirror://ubuntu/pool/main/libi/${PN}/${PN}_${PV}.orig.tar.bz2
	mirror://ubuntu/pool/main/libi/${PN}/${PN}_${PV}-${_UBUNTU_REVISION}.debian.tar.gz"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

RDEPEND=">=dev-libs/libindicate-12.10.0
	x11-libs/qt-gui:4"
DEPEND="${RDEPEND}
	test? ( x11-libs/qt-test:4 )
	virtual/pkgconfig"

src_prepare() {
	EPATCH_FORCE=yes EPATCH_SUFFIX=diff epatch "${WORKDIR}"/debian/patches
	epatch "${FILESDIR}"/${P}-optionaltests.patch
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_EXAMPLES=OFF
		$(cmake-utils_use_build test TESTS)
	)

	cmake-utils_src_configure
}

src_test() {
	local ctestargs
	[[ -n ${TEST_VERBOSE} ]] && ctestargs="--extra-verbose --output-on-failure"

	cd "${CMAKE_BUILD_DIR}"/tests

	VIRTUALX_COMMAND="ctest ${ctestargs}" virtualmake || die
}
