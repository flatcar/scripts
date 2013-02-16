# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-block/thin-provisioning-tools/thin-provisioning-tools-0.1.5-r1.ebuild,v 1.10 2012/12/30 14:57:53 ago Exp $

EAPI=4

inherit eutils

DESCRIPTION="A suite of tools for thin provisioning on Linux."
HOMEPAGE="https://github.com/jthornber/thin-provisioning-tools"
MY_P="${PN}-v${PV}"
SRC_URI="https://github.com/downloads/jthornber/thin-provisioning-tools/${MY_P}.tar.bz2"

S="${WORKDIR}/${MY_P}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm ~hppa ia64 ~mips ppc ppc64 ~s390 ~sh sparc x86 ~amd64-linux ~x86-linux"
IUSE=""

RDEPEND="dev-libs/expat"
DEPEND="${RDEPEND}
		dev-libs/boost"

src_prepare() {
	epatch "${FILESDIR}"/${P}-LDFLAGS.patch
}

src_configure() {
	econf \
		--prefix="${EPREFIX}/" \
		--bindir="${EPREFIX}/sbin" \
		--with-optimisation=""
}

src_install() {
	emake install DESTDIR="${D}" MANDIR=/usr/share/man
}
