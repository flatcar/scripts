# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/maloc/maloc-0.2.1-r3.ebuild,v 1.4 2010/10/31 14:23:12 jlec Exp $

EAPI="3"

inherit autotools eutils

MY_PV="0.2-1"

DESCRIPTION="Minimal Abstraction Layer for Object-oriented C/C++ programs"
HOMEPAGE="http://www.fetk.org/codes/maloc/index.html"
SRC_URI=" http://cam.ucsd.edu/~mholst/codes/${PN}/${PN}-${MY_PV}.tar.gz"

SLOT="0"
LICENSE="GPL-2"
IUSE="mpi static-libs"
KEYWORDS="amd64 ppc x86 ~amd64-linux ~x86-linux"

RDEPEND="
	sys-libs/readline
	mpi? ( virtual/mpi )"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${PN}"

src_prepare() {
	epatch \
		"${FILESDIR}"/${PV}-mpi.patch \
		"${FILESDIR}"/${PV}-asneeded.patch
	eautoreconf
}

src_configure() {
	use mpi && export CC="mpicc"
	# fix install location of libs in Makefile
	sed -e "s|libdir = \${prefix}/lib/\${fetk_cpu_vendor_os}|libdir = \${prefix}/$(get_libdir)/|" \
		-i src/aaa_lib/Makefile.in || \
		die "failed to patch lib Makefile"

	econf \
		$(use_enable mpi) \
		$(use_enable static-libs static) \
		--enable-shared
}

src_install() {
	# install libs and headers
	emake DESTDIR="${D}" install || die "make install failed"

	# install doc
	dohtml doc/index.html || die "failed to install html docs"
}
