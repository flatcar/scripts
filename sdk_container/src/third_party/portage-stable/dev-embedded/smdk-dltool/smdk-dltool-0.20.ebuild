# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-embedded/smdk-dltool/smdk-dltool-0.20.ebuild,v 1.1 2012/01/20 22:44:17 vapier Exp $

EAPI="4"

inherit toolchain-funcs eutils

DESCRIPTION="Tool to communicate with Samsung SMDK boards"
HOMEPAGE="http://www.fluff.org/ben/smdk/tools/"
SRC_URI="http://www.fluff.org/ben/smdk/tools/downloads/smdk-tools-v${PV}.tar.gz"

# Email sent to author on 2012-01-18 querying about license
LICENSE="as-is"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="dev-libs/libusb"
DEPEND="${RDEPEND}"

S=${WORKDIR}/releases/smdk-tools-v${PV}/dltool

src_prepare() {
	epatch "${FILESDIR}"/${P}-add-S3C64xx-support.patch
	epatch "${FILESDIR}"/${P}-build.patch
	tc-export CC
}

src_install() {
	newbin dltool smdk-usbdl
	dodoc readme.txt
}
