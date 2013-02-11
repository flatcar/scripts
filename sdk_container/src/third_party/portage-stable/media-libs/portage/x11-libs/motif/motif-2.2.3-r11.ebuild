# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/motif/motif-2.2.3-r11.ebuild,v 1.1 2012/10/24 18:45:14 ulm Exp $

EAPI=3

inherit eutils flag-o-matic multilib autotools

MY_P=openMotif-${PV}
DESCRIPTION="Legacy Open Motif libraries for old binaries"
HOMEPAGE="http://www.motifzone.net/"
SRC_URI="ftp://ftp.ics.com/openmotif/2.2/${PV}/src/${MY_P}.tar.gz
	mirror://gentoo/openmotif-${PV}-patches-4.tar.bz2"

LICENSE="MOTIF MIT"
SLOT="2.2"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="x11-libs/libXmu
	x11-libs/libXp"

DEPEND="${RDEPEND}
	x11-libs/libXaw
	x11-misc/xbitmaps"

S=${WORKDIR}/${MY_P}

src_prepare() {
	EPATCH_SUFFIX=patch epatch

	# This replaces deprecated, obsoleted and now invalid AC_DEFINE
	# with their proper alternatives.
	sed -i -e 's:AC_DEFINE(\([^)]*\)):AC_DEFINE(\1, [], [\1]):g' \
		configure.in acinclude.m4

	# Build only the libraries
	sed -i -e '/^SUBDIRS/{:x;/\\$/{N;bx;};s/=.*/= lib clients/;}' Makefile.am
	sed -i -e '/^SUBDIRS/{:x;/\\$/{N;bx;};s/=.*/= uil/;}' clients/Makefile.am

	AM_OPTS="--force-missing" eautoreconf
}

src_configure() {
	# get around some LANG problems in make (#15119)
	unset LANG

	# bug #80421
	filter-flags -ftracer

	# feel free to fix properly if you care
	append-flags -fno-strict-aliasing

	econf --with-x --disable-static
}

src_compile() {
	emake -j1 || die "emake failed"
}

src_install() {
	emake -j1 DESTDIR="${D}" install-exec || die "emake install failed"

	# cleanups
	rm -Rf "${D}"/usr/bin
	rm -f "${D}"/usr/$(get_libdir)/*.{so,la,a}

	dodoc README RELEASE RELNOTES BUGREPORT TODO
}
