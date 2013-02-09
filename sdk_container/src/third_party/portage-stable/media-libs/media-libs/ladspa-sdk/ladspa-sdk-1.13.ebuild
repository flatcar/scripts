# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/ladspa-sdk/ladspa-sdk-1.13.ebuild,v 1.8 2012/06/08 23:51:44 zmedico Exp $

inherit eutils multilib toolchain-funcs

MY_PN=${PN/-/_}
MY_P=${MY_PN}_${PV}

DESCRIPTION="The Linux Audio Developer's Simple Plugin API"
HOMEPAGE="http://www.ladspa.org/"
SRC_URI="http://www.ladspa.org/download/${MY_P}.tgz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 hppa ppc ppc64 sparc x86 ~x86-fbsd"
IUSE=""

RDEPEND=""
DEPEND=">=sys-apps/sed-4"

S="${WORKDIR}/${MY_PN}/src"

src_unpack() {
	unpack ${A}
	epatch "${FILESDIR}/${PN}-1.12-fbsd.patch"
	sed -i -e "/^CFLAGS/ s:-O3:${CFLAGS}:" \
		"${S}/makefile" || die "sed makefile failed (CFLAGS)"
	sed -i -e "s/^CXXFLAGS*/CXXFLAGS = ${CXXFLAGS} \$(INCLUDES) -Wall -fPIC\n#/" \
		 "${S}/makefile" || die "sed makefile failed (CXXFLAGS)"
	sed -i -e 's:-mkdirhier:mkdir\ -p:g' \
		"${S}/makefile" || die "sed makefile failed (mkdirhier)"
	sed -i -e 's:-sndfile-play*:@echo Disabled \0:' \
		"${S}/makefile" || die "sed makefile failed (sound playing tests)"
}

src_compile() {
	emake targets CC=$(tc-getCC) CPP=$(tc-getCXX) || die
}

src_install() {
	emake \
		INSTALL_PLUGINS_DIR="${D}/usr/$(get_libdir)/ladspa" \
		INSTALL_INCLUDE_DIR="${D}/usr/include" \
		INSTALL_BINARY_DIR=$"${D}/usr/bin" \
		install || die "make install failed"

	dohtml ../doc/*.html || die "dohtml failed"

	# Needed for apps like rezound
	dodir /etc/env.d
	echo "LADSPA_PATH=/usr/$(get_libdir)/ladspa" > "${D}/etc/env.d/60ladspa"
}
