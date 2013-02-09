# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/ladspa-cmt/ladspa-cmt-1.16-r2.ebuild,v 1.1 2012/11/27 12:08:45 aballier Exp $

EAPI=4

inherit eutils multilib toolchain-funcs

IUSE=""

S="${WORKDIR}/cmt/src"
MY_P="cmt_src_${PV}"

DESCRIPTION="CMT (computer music toolkit) Lasdpa library plugins"
HOMEPAGE="http://www.ladspa.org/"
SRC_URI="http://www.ladspa.org/download/${MY_P}.tgz"

KEYWORDS="~alpha ~amd64 ~hppa ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
LICENSE="LGPL-2.1"
SLOT="0"

DEPEND="media-libs/ladspa-sdk
	>=sys-apps/sed-4"
RDEPEND=""

src_prepare() {
	sed -i \
		-e "/^CFLAGS/ s/-O3/${CFLAGS}/" \
		-e 's|/usr/local/include||g' \
		-e 's|/usr/local/lib||g' makefile \
			|| die "sed makefile failed"
	sed -i -e "s/^CXXFLAGS*/CXXFLAGS = ${CXXFLAGS} \$(INCLUDES) -Wall -fPIC\n#/" \
		 "${S}/makefile" || die "sed makefile failed (CXXFLAGS)"

	cd "${S}"
	epatch "${FILESDIR}/${P}-mallocstdlib.patch"
	epatch "${FILESDIR}/${P}-respect-ldflags.patch"
	epatch "${FILESDIR}/${P}-sa.patch"
	use userland_Darwin && epatch "${FILESDIR}/${P}-darwin.patch"
}

src_compile() {
	tc-export CXX
	emake || die "emake failed"
}

src_install() {
	insinto /usr/share/ladspa/rdf/
	doins "${FILESDIR}/cmt.rdf"

	insopts -m755
	insinto /usr/$(get_libdir)/ladspa
	doins ../plugins/*.so

	dodoc ../README
	dohtml ../doc/*
}
