# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-embedded/u-boot-tools/u-boot-tools-2012.10.ebuild,v 1.4 2012/11/10 07:13:49 vapier Exp $

EAPI="4"

inherit toolchain-funcs

MY_P="u-boot-${PV/_/-}"
DESCRIPTION="utilities for working with Das U-Boot"
HOMEPAGE="http://www.denx.de/wiki/U-Boot/WebHome"
SRC_URI="ftp://ftp.denx.de/pub/u-boot/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE=""

S=${WORKDIR}/${MY_P}

src_prepare() {
	sed -i -e "s:-g ::" tools/Makefile || die
	# This has been fixed upstream after 2012.10
	sed -i '/include.*config.h/d' tools/env/fw_env.[ch] || die
	# Make sure we find local u-boot headers first #429302
	ln -s ../include/image.h tools/ || die
}

src_compile() {
	emake \
		HOSTSTRIP=: \
		HOSTCC="$(tc-getCC)" \
		HOSTCFLAGS="${CFLAGS} ${CPPFLAGS}"' $(HOSTCPPFLAGS)' \
		HOSTLDFLAGS="${LDFLAGS}" \
		CONFIG_ENV_OVERWRITE=y \
		tools-all
}

src_install() {
	cd tools
	dobin bmp_logo gen_eth_addr img2srec mkimage
	dobin easylogo/easylogo
	dobin env/fw_printenv
	dosym fw_printenv /usr/bin/fw_setenv
	insinto /etc
	doins env/fw_env.config
}
