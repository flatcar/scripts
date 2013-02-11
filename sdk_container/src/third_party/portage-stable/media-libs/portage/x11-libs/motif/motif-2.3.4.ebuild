# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/motif/motif-2.3.4.ebuild,v 1.10 2013/01/02 00:05:11 ulm Exp $

EAPI=4

inherit autotools eutils flag-o-matic multilib

DESCRIPTION="The Motif user interface component toolkit"
HOMEPAGE="http://sourceforge.net/projects/motif/
	http://motif.ics.com/"
SRC_URI="mirror://sourceforge/project/motif/Motif%20${PV}%20Source%20Code/${P}-src.tgz"

LICENSE="LGPL-2.1+ MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~ia64-hpux ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="examples jpeg png static-libs unicode xft"

RDEPEND="x11-libs/libXmu
	x11-libs/libXp
	unicode? ( virtual/libiconv )
	xft? ( x11-libs/libXft )
	jpeg? ( virtual/jpeg )
	png? ( >=media-libs/libpng-1.4 )"
DEPEND="${RDEPEND}
	sys-devel/flex
	|| ( dev-util/byacc sys-freebsd/freebsd-ubin )
	x11-misc/xbitmaps"

src_prepare() {
	epatch "${FILESDIR}/${P}-solaris.patch"
	epatch "${FILESDIR}/${PN}-2.3.2-sanitise-paths.patch"
	[[ ${CHOST} == *-solaris2.11 ]] \
		&& epatch "${FILESDIR}/${PN}-2.3.2-solaris-2.11.patch"

	# disable compilation of demo binaries
	sed -i -e '/^SUBDIRS/{:x;/\\$/{N;bx;};s/[ \t\n\\]*demos//;}' Makefile.am

	# add X.Org vendor string to aliases for virtual bindings
	echo -e '"The X.Org Foundation"\t\t\t\t\tpc' >>bindings/xmbind.alias

	AT_M4DIR=. eautoreconf
}

src_configure() {
	# get around some LANG problems in make (#15119)
	LANG=C

	# bug #80421
	filter-flags -ftracer

	# feel free to fix properly if you care
	append-flags -fno-strict-aliasing

	# For Solaris Xos_r.h :(
	[[ ${CHOST} == *-solaris2.11 ]] && append-flags -DNEED_XOS_R_H=1

	if use !elibc_glibc && use !elibc_uclibc && use unicode; then
		# libiconv detection in configure script doesn't always work
		# http://bugs.motifzone.net/show_bug.cgi?id=1423
		export LIBS="${LIBS} -liconv"
	fi

	# "bison -y" causes runtime crashes #355795
	export YACC=byacc

	econf --with-x \
		$(use_enable static-libs static) \
		$(use_enable unicode utf8) \
		$(use_enable xft) \
		$(use_enable jpeg) \
		$(use_enable png)
}

src_compile() {
	make clean			# remove pre-made bison parsers
	emake MWMRCDIR="${EPREFIX}"/etc/X11/mwm
}

src_install() {
	emake DESTDIR="${D}" MWMRCDIR="${EPREFIX}"/etc/X11/mwm install

	# mwm default configs
	insinto /usr/share/X11/app-defaults
	newins "${FILESDIR}"/Mwm.defaults Mwm

	if use examples; then
		emake -C demos DESTDIR="${D}" install-data
		dodir /usr/share/doc/${PF}/demos
		mv "${ED}"/usr/share/Xm/* "${ED}"/usr/share/doc/${PF}/demos || die
	fi
	rm -rf "${ED}"/usr/share/Xm

	# don't install libtool archives
	rm -f "${ED}"/usr/$(get_libdir)/*.la

	dodoc BUGREPORT ChangeLog README RELEASE RELNOTES TODO
}
