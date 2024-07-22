# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-info toolchain-funcs

DESCRIPTION="utility to administer the IP virtual server services"
HOMEPAGE="http://linuxvirtualserver.org/"
SRC_URI="https://kernel.org/pub/linux/utils/kernel/ipvsadm/ipvsadm-${PV}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ia64 ~arm64 ~ppc ppc64 ~s390 sparc x86"
IUSE="static-libs"

RDEPEND="
	dev-libs/libnl:=
	>=dev-libs/popt-1.16
"

BDEPEND="
	${RDEPEND}
	virtual/pkgconfig
"

PATCHES=( "${FILESDIR}/${PN}"-1.31-buildsystem.patch )

src_configure() {
    cat <<EOF >config.mk
HAVE_NL = 1
AR = $(tc-getAR)
CC = $(tc-getCC)
PKG_CONFIG = $(tc-getPKG_CONFIG)
LINK_WITH = shared
BUILD_LIBS = $(usex static-libs both shared)
LIB = /usr/$(get_libdir)
CFLAGS = ${CFLAGS}
LDFLAGS = ${LDFLAGS}
EOF
}

src_install() {
	default
	rm -rf "${D}/etc/rc.d/"

	insinto /usr/include/ipvs
	newins libipvs/libipvs.h ipvs.h
	doins libipvs/ip_vs.h
}

pkg_postinst() {
	einfo "You will need a kernel that has ipvs patches to use LVS."
}
