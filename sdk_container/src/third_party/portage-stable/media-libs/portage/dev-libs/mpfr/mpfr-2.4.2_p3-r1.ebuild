# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/mpfr/mpfr-2.4.2_p3-r1.ebuild,v 1.1 2011/10/03 15:17:49 vapier Exp $

# this ebuild is only for the libmpfr.so.1 ABI SONAME

EAPI="3"

inherit eutils

MY_PV=${PV/_p*}
MY_P=${PN}-${MY_PV}
DESCRIPTION="library for multiple-precision floating-point computations with exact rounding"
HOMEPAGE="http://www.mpfr.org/"
SRC_URI="http://www.mpfr.org/mpfr-${MY_PV}/${MY_P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="1"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~sparc-fbsd ~x86-fbsd"
IUSE=""

RDEPEND=">=dev-libs/gmp-4.1.4-r2"
DEPEND="${RDEPEND}"

S=${WORKDIR}/${MY_P}

src_prepare() {
	epatch "${FILESDIR}"/${MY_PV}/patch*
	sed -i '/if test/s:==:=:' configure #261016
	find . -type f -print0 | xargs -0 touch -r configure
}

src_configure() {
	econf --disable-static
}

src_compile() {
	emake libmpfr.la || die
}

src_install() {
	emake install-libLTLIBRARIES DESTDIR="${D}" || die
	rm "${D}"/usr/*/libmpfr.{la,so} || die
}
