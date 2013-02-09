# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/raspberrypi-userland/raspberrypi-userland-0_pre20121024.ebuild,v 1.2 2012/10/25 01:10:45 chithanh Exp $

EAPI=5

inherit cmake-utils

DESCRIPTION="Raspberry Pi userspace tools and libraries for the VideoCore IV GPU"
HOMEPAGE="https://github.com/raspberrypi/userland"

if [[ ${PV} == 9999* ]]; then
	inherit git-2
	EGIT_REPO_URI="git://github.com/${PN/-//}.git"
	SRC_URI=""
else
	SRC_URI="mirror://gentoo/${P}.tar.xz"
fi

LICENSE="BSD"
SLOT="0"
KEYWORDS="~arm"

# TODO:
# * port vcfiled init script
# * stuff is still installed to hardcoded /opt/vc location, investigate whether
#   anything else depends on it being there
# * live ebuild

src_unpack() {
	if [[ ${PV} == 9999* ]]; then
		git-2_src_unpack
	else
		default
		mv ${PN}-*/ ${P}/ || die
	fi
}

src_prepare() {
	# missing from upstream repo, would be installed to wrong directory anyway
	# https://github.com/raspberrypi/userland/issues/1
	sed -i "/10-vchiq.rules/d" interface/vchiq_arm/CMakeLists.txt || die
	# init script for Debian, not useful on Gentoo
	sed -i "/DESTINATION \/etc\/init.d/,+2d" interface/vmcs_host/linux/vcfiled/CMakeLists.txt || die
	# we have our env.d file for this
	sed -i "/\/etc\/ld.so.conf/d" makefiles/cmake/vmcs.cmake
}

src_configure() {
	# toolchain file not needed, but build fails if it is not specified
	local mycmakeargs="-DCMAKE_TOOLCHAIN_FILE=/dev/null"
	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install
	doenvd "${FILESDIR}"/04${PN}
}
